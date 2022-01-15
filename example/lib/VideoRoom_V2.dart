import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

import 'package:janus_client_example/conf.dart';

class VideoRoomV2 extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<VideoRoomV2> {
  late JanusClient j;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  Map<int, RTCVideoRenderer> remoteRenderers = {};
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusPlugin plugin;
  Map<int, JanusPlugin> subscriberHandles = {};
  late int myId;

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

  _newRemoteFeed(feed) async {
    print('remote plugin attached');

    if (subscriberHandles.containsKey(feed)) return;
    if (feed == myId) return;
    var value = await session.attach<JanusVideoRoomPlugin>();
    setState(() {
      subscriberHandles[feed] = value;
    });

    var register = {
      "request": "join",
      "room": 1234,
      "ptype": "subscriber",
      "feed": feed,
    };
    subscriberHandles[feed]?.remoteStream?.listen((stream) async {
      print('remote stream recieved');
      setState(() {
        remoteRenderers[feed] = new RTCVideoRenderer();
      });
      await remoteRenderers[feed]?.initialize();
      remoteRenderers[feed]?.srcObject = stream;
    });
    await subscriberHandles[feed]?.send(data: register);
    subscriberHandles[feed]?.messages?.listen((msg) async {
      print('subscriber event');
      print(msg);
      if (msg.event['janus'] == 'event') {
        if (msg.jsep != null) {
          await subscriberHandles[feed]?.handleRemoteJsep(msg.jsep);
          var body = {"request": "start", "room": 1234};
          await subscriberHandles[feed]?.send(
              data: body,
              jsep: await subscriberHandles[feed]?.createAnswer(
                  audioRecv: false,
                  videoRecv: false,
                  audioSend: true,
                  videoSend: true));
        }
        var pluginData = msg.event['plugindata'];
        if (pluginData != null) {
          Map<String, dynamic> data = pluginData['data'];
          if (data['videoroom'] == 'attached') {
            print('setting subscriber loop');
          }
        }
      }
    });
  }

  Future<void> initPlatformState() async {
    await initRenderers();
    setState(() {
      rest = RestJanusTransport(url: servermap['janus_rest']);
      ws = WebSocketJanusTransport(url: servermap['janus_ws']);
      j = JanusClient(transport: ws, iceServers: [
        RTCIceServer(
            urls: "stun:stun1.l.google.com:19302", username: "", credential: "")
      ]);
    });
    var sess = await j.createSession();
    session = sess;
    plugin = await session.attach<JanusVideoRoomPlugin>();
    final mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth':
              '1280', // Provide your own width, height and frame rate here
          'minHeight': '720',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      }
    };
    var stream =
        await plugin.initializeMediaDevices(mediaConstraints: mediaConstraints);
    setState(() {
      remoteRenderers[0] = new RTCVideoRenderer();
    });
    await remoteRenderers[0]?.initialize();
    setState(() {
      remoteRenderers[0]?.srcObject = stream;
    });

    var register = {
      "request": "join",
      "ptype": "publisher",
      "room": 1234,
      "display": "Shivansh" + randomString()
    };
    print('got response');
    print(await plugin.send(data: register));
    plugin.messages?.listen((msg) async {
      print('on message');
      print(msg);

      if (msg.event['janus'] == 'event') {
        if (msg.jsep != null) {
          print('handling sdp');
          await plugin.handleRemoteJsep(msg.jsep);
        }
        var pluginData = msg.event['plugindata'];
        if (pluginData != null) {
          var data = pluginData['data'];
          if (data != null) {
            if (data["publishers"] != null) {
              List<dynamic> list = data["publishers"];
              print('got publihers');
              print(list);
              list.forEach((element) {
                _newRemoteFeed(element['id']);
              });
            }
            if (data['videoroom'] == 'event' &&
                    data.containsKey('unpublished') ||
                data.containsKey('leaving')) {
              print('recieved unpublishing event on subscriber handle');
              int leaving = data['leaving'];
              int unpublished = data['unpublished'];
              if (remoteRenderers.containsKey(unpublished)) {
                RTCVideoRenderer? renderer;
                setState(() {
                  renderer = remoteRenderers.remove(unpublished);
                });
                renderer?.srcObject = null;
              }
              if (remoteRenderers.containsKey(leaving)) {
                RTCVideoRenderer? renderer;
                setState(() {
                  renderer = remoteRenderers.remove(leaving);
                });
                renderer?.srcObject = null;
              }
              if (subscriberHandles.containsKey(data['unpublished'])) {
                await subscriberHandles[data['unpublished']]?.dispose();
                subscriberHandles.remove(data['unpublished']);
              }
            }
            if (data['videoroom'] == 'joined') {
              print('user joined configuring video stream');
              myId = data['id'];
              var publish = {"request": "publish", "bitrate": 10000000};
              RTCSessionDescription offer = await plugin.createOffer(
                  videoRecv: true,
                  audioRecv: true,
                  videoSend: false,
                  audioSend: false);
              print(await plugin.send(data: publish, jsep: offer));
            }
          }
        }
      }
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

  cleanUpResources() {
    subscriberHandles.entries.forEach((element) async {
      await element.value.hangup();
      await element.value.dispose();
      subscriberHandles.remove(element.key);
    });
    remoteRenderers.forEach((key, value) {});
    remoteRenderers.entries.forEach((element) async {
      try {
        element.value.srcObject = null;
        remoteRenderers.remove(element.key);
      } catch (e) {}
      await element.value.dispose();
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
                  plugin.switchCamera();
                })
          ],
          title: const Text('janus_client'),
        ),
        body: GridView.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: remoteRenderers.entries.toList().length,
            itemBuilder: (context, index) {
              return RTCVideoView(remoteRenderers.entries.toList()[index].value,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: true);
            }));

    //     GridView.count(
    //     crossAxisCount: 2,
    //     shrinkWrap: true,
    //     childAspectRatio: 1,
    //     crossAxisSpacing: 30,
    //     mainAxisSpacing: 30,
    //     children: [
    //     ,
    //     ...remoteRenderers.entries.map((e)
    // {
    //   return RTCVideoView(
    //     e.value,
    //     mirror: true,
    //     objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    //   );
    // }).toList()
    // ],
    // ));
  }
}
