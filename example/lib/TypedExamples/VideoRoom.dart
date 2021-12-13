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
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  Map<int, RTCVideoRenderer> remoteRenderers = {};
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusVideoRoomPlugin plugin;
  JanusVideoRoomPlugin? remoteHandle;
  late int myId;
  int myRoom = 1234;
  dynamic feedStreams = {};
  dynamic subscriptions = {};
  dynamic feeds = {};
  Map<String, int> subStreams = {};
  Map<int, MediaStream?> mediaStreams = {};

  @override
  initState() {
    super.initState();
    initRenderers();
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await initRenderers();
  }

  initRenderers() async {
    setState(() {
      _localRenderer = RTCVideoRenderer();
    });
    await _localRenderer.initialize();
  }

  subscribeTo(List<Map<String, dynamic>> sources) async {
    if (sources.length == 0) return;
    var streams = (sources).map((e) => PublisherStream(mid: e['mid'], feed: e['feed'])).toList();
    // for (PublisherStream stream in streams) {
    //   // removing duplicate subscriptions before any processing
    //   if (subscriptions[stream.feed] != null && subscriptions[stream.feed][stream.mid]) {
    //     streams.remove(stream);
    //   }
    // }
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
            subStreams["janus" + element.mid!] = element.feedId!;
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
      // if (event.flowing!) {
        String mid = event.mid!;
        print(mid);
        print(subStreams[mid]);
        // if (subStreams[mid] != null) {
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
        // }
      // }
    });
    return;
  }

  Future<void> joinRoom() async {
    await initRenderers();
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    j = JanusClient(transport: ws, isUnifiedPlan: true, iceServers: [RTCIceServer(url: "stun:stun1.l.google.com:19302", username: "", credential: "")]);
    session = await j.createSession();
    plugin = await session.attach<JanusVideoRoomPlugin>();
    MediaStream? stream = await plugin.initializeMediaDevices(mediaConstraints: {"video": true, "audio": true});
    setState(() {
      remoteRenderers[0] = RTCVideoRenderer();
    });
    await remoteRenderers[0]?.initialize();
    remoteRenderers[0]?.srcObject = stream;
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
            // print(stream);
            feedStreams[publisher.id] = {"id": publisher.id, "display": publisher.display, "streams": publisher.streams};
            publisherStreams.add({"feed": publisher.id, ...stream.toJson()});
            if (publisher.id != null && stream.mid != null) {
              subStreams["janus" + stream.mid!] = publisher.id!;
            }
          }
        }
        subscribeTo(publisherStreams);
      }
      if (data is VideoRoomNewPublisherEvent) {
        List<Map<String, dynamic>> publisherStreams = [];
        for (Publishers publisher in data.publishers ?? []) {
          feedStreams[publisher.id] = {"id": publisher.id, "display": publisher.display, "streams": publisher.streams};
          for (Streams stream in publisher.streams ?? []) {
            // print(stream);
            publisherStreams.add({"feed": publisher.id, ...stream.toJson()});
            if (publisher.id != null && stream.mid != null) {
              subStreams["janus" + stream.mid!] = publisher.id!;
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
      }
      await plugin.handleRemoteJsep(event.jsep);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    plugin.dispose();
    session.dispose();
    cleanUpResources();
  }

  callEnd() async {
    await plugin.hangup();

    _localRenderer.srcObject = null;
    try {
      await _localRenderer.dispose();
    } catch (e) {}

    plugin.dispose();
    cleanUpResources();
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: remoteRenderers.entries.toList().length,
            itemBuilder: (context, index) {
              return RTCVideoView(remoteRenderers.entries.toList()[index].value, filterQuality: FilterQuality.high, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: true);
            }));
  }
}
