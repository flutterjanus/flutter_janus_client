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
    if (remoteHandle != null) {
      return;
    }
    remoteHandle = await session.attach<JanusVideoRoomPlugin>();
    print(sources);
    var streams=(sources).map((e) => PublisherStream(mid: e['mid'], feed: e['feed'])).toList();
    var start=await remoteHandle?.joinSubscriber(1234, streams:streams);
    remoteHandle?.typedMessages?.listen((event) async{
      Object data=event.event.plugindata?.data;
      if(data is VideoRoomAttachedEvent){
        print('Attached event');
        print(data.streams);
        // data.streams[0].
      }
      if(event.jsep!=null){
        await remoteHandle?.handleRemoteJsep(event.jsep);
        await start!();

      }
    });
    remoteHandle?.remoteTrack?.listen((event) {
      print('recieved remote track'+event.track.toString());
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
    _localRenderer.srcObject = stream;
    await plugin.joinPublisher(
      1234,
      displayName: "Shivansh",
    );
    plugin.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        (await plugin.publishMedia());
        List<Map<String, dynamic>> publisherStreams = [];
        for (Publishers publisher in data.publishers ?? []) {
          for (Streams stream in publisher.streams ?? []) {
            // print(stream);
            publisherStreams.add({"feed": publisher.id, ...stream.toJson()});
          }
        }
        subscribeTo(publisherStreams);
      }
      if (data is VideoRoomNewPublisherEvent) {
        print('got new publishers');
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
              return RTCVideoView(remoteRenderers.entries.toList()[index].value, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover, mirror: true);
            }));
  }
}
