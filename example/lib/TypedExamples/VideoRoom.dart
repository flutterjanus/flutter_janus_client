import 'dart:html';

import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/Helper.dart';
import 'dart:async';

import 'package:janus_client_example/conf.dart';

class TypedVideoRoomV2Unified extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<TypedVideoRoomV2Unified> {
  late JanusClient j;
  Map<int, RTCVideoRenderer> remoteRenderers = {};
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusVideoRoomPlugin plugin;
  JanusVideoRoomPlugin? remoteHandle;
  late int myId;
  MediaStream? myStream;
  int myRoom = 1234;
  Map<int, dynamic> feedStreams = {};
  Map<int?,dynamic> subscriptions = {};
  Map<int,dynamic> feeds = {};
  Map<String, int> subStreams = {};
  Map<int, MediaStream?> mediaStreams = {};

  @override
  initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  subscribeTo(List<Map<String, dynamic>> sources) async {
    if (sources.length == 0) return;
    var streams = (sources).map((e) => PublisherStream(mid: e['mid'], feed: e['feed'])).toList();
    if (remoteHandle != null) {
      await remoteHandle?.subscribeToStreams(streams);
      return;
    }
    remoteHandle = await session.attach<JanusVideoRoomPlugin>();
    print(sources);
    var start = await remoteHandle?.joinSubscriber(1234, streams: streams);
    remoteHandle?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomAttachedEvent) {
        print('Attached event');
        data.streams?.forEach((element) {
          if (element.mid != null && element.feedId != null) {
            subStreams[element.mid!] = element.feedId!;
          }
          // to avoid duplicate subscriptions
          if (subscriptions[element.feedId] == null) subscriptions[element.feedId] = {};
          subscriptions[element.feedId][element.mid] = true;
        });
        print('substreams');
        print(subStreams);
      }
      if (event.jsep != null) {
        await remoteHandle?.handleRemoteJsep(event.jsep);
        await start!();
      }
    });
    remoteHandle?.remoteTrack?.listen((event) async {
      String mid = event.mid!;
      print(mid);
      if (subStreams[mid] != null) {
        print(subStreams[mid]);
        int feedId = subStreams[mid]!;
        print('got feed id' + feedId.toString());
        setState(() {
          remoteRenderers.putIfAbsent(feedId, () => RTCVideoRenderer());
        });
        MediaStream mediaStream = await createLocalMediaStream('stream' + feedId.toString());
        setState(() {
          mediaStreams.putIfAbsent(feedId, () => mediaStream);
        });
        await remoteRenderers[feedId]?.initialize();
        mediaStreams[feedId] = mediaStreams[feedId]?.clone();
        mediaStreams[feedId]?.addTrack(event.track!);
        remoteRenderers[feedId]?.srcObject = mediaStreams[feedId];
      }
    });
    return;
  }

  Future<void> joinRoom() async {
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    j = JanusClient(transport: ws, isUnifiedPlan: true, iceServers: [RTCIceServer(url: "stun:stun1.l.google.com:19302", username: "", credential: "")]);
    session = await j.createSession();
    plugin = await session.attach<JanusVideoRoomPlugin>();
    myStream = await plugin.initializeMediaDevices(mediaConstraints: {"video": true, "audio": true});
    setState(() {
      remoteRenderers[0] = RTCVideoRenderer();
    });
    await remoteRenderers[0]?.initialize();
    remoteRenderers[0]?.srcObject = myStream;
    await plugin.joinPublisher(
      1234,
      displayName: "Shivansh",
    );
    plugin.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        (await plugin.publishMedia(bitrate: 3000000));
        List<Map<String, dynamic>> publisherStreams = [];
        for (Publishers publisher in data.publishers ?? []) {
          for (Streams stream in publisher.streams ?? []) {
            feedStreams[publisher.id!] = {"id": publisher.id, "display": publisher.display, "streams": publisher.streams};
            publisherStreams.add({"feed": publisher.id, ...stream.toJson()});
            if (publisher.id != null && stream.mid != null) {
              subStreams[stream.mid!] = publisher.id!;
              print("substreams is:");
              print(subStreams);
            }
          }
        }
        subscribeTo(publisherStreams);
      }
      if (data is VideoRoomNewPublisherEvent) {
        List<Map<String, dynamic>> publisherStreams = [];
        for (Publishers publisher in data.publishers ?? []) {
          feedStreams[publisher.id!] = {"id": publisher.id, "display": publisher.display, "streams": publisher.streams};
          for (Streams stream in publisher.streams ?? []) {
            publisherStreams.add({"feed": publisher.id, ...stream.toJson()});
            if (publisher.id != null && stream.mid != null) {
              subStreams[stream.mid!] = publisher.id!;
              print("substreams is:");
              print(subStreams);
            }
          }
        }
        print('got new publishers');
        print(publisherStreams);
        subscribeTo(publisherStreams);
      }
      if (data is VideoRoomLeavingEvent) {
        print('publisher is leaving');
        print(data.leaving);
        unSubscribeStream(data.leaving!);
      }
      if (data is VideoRoomConfigured) {
        print('typed event with jsep' + event.jsep.toString());
        await plugin.handleRemoteJsep(event.jsep);
      }
    });
  }

  Future<void> unSubscribeStream(int id) async {
// Unsubscribe from this publisher
    var feed = this.feedStreams[id];
    if (feed == null) return;
    this.feedStreams.remove(id);
    // Send an unsubscribe request
    this.remoteRenderers[id]?.srcObject = null;
    this.remoteRenderers[id]?.dispose();
    this.remoteRenderers.remove(id);
    MediaStream? streamRemoved=this.mediaStreams.remove(id);
    streamRemoved?.getTracks().forEach((element) async{
      await element.stop();
    });
    var unsubscribe = {
      "request": "unsubscribe",
      "streams": [
        {feed: id}
      ]
    };
    if (remoteHandle != null) await remoteHandle?.send(data: {"message": unsubscribe});
    this.subscriptions.remove(id);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    plugin.dispose();
    session.dispose();
  }

  callEnd() async {
    await plugin.hangup();
    for (int i = 0; i < feedStreams.keys.length; i++) {
      await unSubscribeStream(feedStreams.keys.elementAt(i));
    }
    for (int i = 0; i < remoteRenderers.keys.length; i++) {
      var value = remoteRenderers.entries.elementAt(i);
      value.value.srcObject?.dispose();
      value.value.srcObject = null;
      await value.value.dispose();
      remoteRenderers.remove(value.key);
    }
    subStreams.clear();
    subscriptions.clear();
    // stop all tracks and then dispose
    myStream?.getTracks().forEach((element)async {
     await element.stop();
   });
   await myStream?.dispose();
    await remoteHandle?.dispose();
    print(mediaStreams);
    print(remoteRenderers);
    print(feedStreams);
    print(subStreams);
    await plugin.dispose();
    session.dispose();
  }

  cleanUpResources() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                icon: Icon(
                  Icons.call,
                  color: Colors.greenAccent,
                ),
                onPressed: () async {
                  await this.joinRoom();
                }),
            IconButton(
                icon: Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                onPressed: () async {
                  await callEnd();
                }),
            IconButton(
                icon: Icon(
                  Icons.switch_camera,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (plugin != null) {
                    // plugin.switchCamera();
                  }
                })
          ],
          title: const Text('janus_client'),
        ),
        body: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: remoteRenderers.entries.toList().length,
            itemBuilder: (context, index) {
              return RTCVideoView(remoteRenderers.entries.toList()[index].value, filterQuality: FilterQuality.high, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: true);
            }));
  }
}
