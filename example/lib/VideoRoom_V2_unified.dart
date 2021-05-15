import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

class VideoRoomV2Unified extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<VideoRoomV2Unified> {
  JanusClient j;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  Map<int, RTCVideoRenderer> remoteRenderers = {};
  RestJanusTransport rest;
  WebSocketJanusTransport ws;
  JanusSession session;
  JanusPlugin plugin;
  Map<int, JanusPlugin> subscriberHandles = {};
  JanusPlugin subscriberHandle;
  int myId;

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  _newRemoteFeed(feed) async {
    print('remote plugin attached');

    if (subscriberHandles.containsKey(feed)) return;
    if (feed == myId) return;
    if (subscriberHandle == null) {
      await session.attach(JanusPlugins.VIDEO_ROOM).then((value) {
        setState(() {
          subscriberHandle = value;
        });
      });
    }

    var register = {
      "request": "join",
      "room": 1234,
      "ptype": "subscriber",
      "streams": [
        {"feed": feed}
      ],
    };
    subscriberHandle.remoteTrack.listen((event) async {
      print('remote track recieved');
      print(event.toMap());
      setState(() {
        remoteRenderers[feed] = new RTCVideoRenderer();
      });
      await remoteRenderers[feed].initialize();

      var stream = event.stream;
      // if (stream != null) {
      //   stream.addTrack(event.track);
      //   await remoteRenderers[feed].initialize();
      //   remoteRenderers[feed].srcObject = stream;
      // }
    });
    // subscriberHandles[feed].webRTCHandle.peerConnection.onAddStream =
    //     (stream) async {
    //   print('remote stream recieved');
    //   setState(() {
    //     remoteRenderers[feed] = new RTCVideoRenderer();
    //   });
    //   await remoteRenderers[feed].initialize();
    //   remoteRenderers[feed].srcObject = stream;
    // };
    // subscriberHandles[feed].webRTCHandle.peerConnection.onRemoveStream =
    //     (stream) async {
    //   print('remote stream recieved');
    //   print(stream.getTracks().length.toString() + ' Tracks Found!');
    //
    //   setState(() {
    //     remoteRenderers[feed] = new RTCVideoRenderer();
    //   });
    //   await remoteRenderers[feed].initialize();
    //   remoteRenderers[feed].srcObject = stream;
    // };
    await subscriberHandle.send(data: register);
    subscriberHandle.messages.listen((msg) async {
      print('subscriber event');
      print(msg);
      if (msg.event['janus'] == 'event') {
        if (msg.jsep != null) {
          await subscriberHandle.handleRemoteJsep(msg.jsep);
          var body = {"request": "start", "room": 1234};
          await subscriberHandle.send(
              data: body,
              jsep: await subscriberHandle.createAnswer(
                  offerToReceiveAudio: false, offerToReceiveVideo: false));
        }
        var pluginData = msg.event['plugindata'];
        if (pluginData != null) {
          Map<String, dynamic> data = pluginData['data'];
          if (data != null) {
            if (data['videoroom'] == 'attached') {
              print('setting subscriber loop');
            }
          }
        }
      }
    });
  }

  Future<void> initPlatformState() async {
    setState(() {
      rest =
          RestJanusTransport(url: 'https://unified-janus.onemandev.tech/rest');
      ws = WebSocketJanusTransport(
          url: 'wss://master-janus.onemandev.tech/websocket');
      j = JanusClient(transport: ws, isUnifiedPlan: true, iceServers: [
        RTCIceServer(
            url: "stun:stun1.l.google.com:19302", username: "", credential: "")
      ]);
    });
    await j.createSession().then((value) {
      print(value.sessionId);
      setState(() {
        session = value;
      });
    });

    print(session.sessionId);
    plugin = await session.attach(JanusPlugins.VIDEO_ROOM);
    print('got handleId');
    print(plugin.handleId);
    // _localRenderer.srcObject = await plugin.initializeMediaDevices();

    var register = {
      "request": "join",
      "ptype": "publisher",
      "room": 1234,
      "display": "Shivansh"
    };
    print('got response');
    print(await plugin.send(data: register));
    plugin.messages.listen((msg) async {
      print('on message');
      print(msg);
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
  }

  callEnd() async {
    if (plugin != null) {
      await plugin.hangup();
    }

    if (_localRenderer.renderVideo) {
      _localRenderer.srcObject = null;
      await _localRenderer.dispose();
    }
    if (plugin != null) {
      plugin.dispose();
    }
    subscriberHandles.entries.forEach((element) async {
      if (element.value != null) {
        await element.value.hangup();
        subscriberHandles.remove(element.key);
      }
    });
    remoteRenderers.entries.forEach((element) async {
      element.value.srcObject = null;
      await element.value.dispose();
      remoteRenderers.remove(element.key);
    });
  }

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
                  await this.initRenderers();
                  await this.initPlatformState();
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
                    plugin.switchCamera();
                  }
                })
          ],
          title: const Text('janus_client'),
        ),
        body: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          childAspectRatio: 1,
          crossAxisSpacing: 30,
          mainAxisSpacing: 30,
          children: [
            RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            ...remoteRenderers.entries.map((e) {
              return RTCVideoView(
                e.value,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              );
            }).toList()
          ],
        ));
  }
}
