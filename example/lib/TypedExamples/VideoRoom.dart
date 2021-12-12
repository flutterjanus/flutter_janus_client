import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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
  late JanusVideoRoomPlugin remoteFeed;
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

  Future<void> joinRoom() async {
    await initRenderers();
    setState(() {
      ws = WebSocketJanusTransport(url: servermap['janus_ws']);
      j = JanusClient(
          loggerLevel: Level.OFF,
          transport: ws, isUnifiedPlan: true, iceServers: [RTCIceServer(url: "stun:stun1.l.google.com:19302", username: "", credential: "")]);
    });
    var sess = await j.createSession();
    session = sess;

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
        (await plugin.publishMedia(bitrate: 2000000));
      }
      if(data is VideoRoomNewPublisherEvent){
        print('got new publishers');
        print(data.publishers.toString());
        // data.publishers[0].streams[0].
      }
      await plugin.handleRemoteJsep(event.jsep);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (plugin != null) {
      plugin.dispose();
    }
    if (session != null) {
      session.dispose();
    }
    cleanUpResources();
  }

  callEnd() async {
    if (plugin != null) {
      await plugin.hangup();
    }

    if (_localRenderer != null) {
      _localRenderer.srcObject = null;
      try {
        await _localRenderer.dispose();
      } catch (e) {}
    }

    if (plugin != null) {
      plugin.dispose();
    }
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
