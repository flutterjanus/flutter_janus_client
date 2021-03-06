import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

class VideoRoomV2 extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<VideoRoomV2> {
  JanusClient j;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  Map<int, RTCVideoRenderer> remoteRenderers = {};
  RestJanusTransport rest;
  WebSocketJanusTransport ws;
  JanusSession session;
  JanusPlugin plugin;
  Map<int, JanusPlugin> subscriberHandles = {};

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

    await session.attach(JanusPlugins.VIDEO_ROOM).then((value) {
      setState(() {
        subscriberHandles[feed] = value;
      });
    });

    var register = {
      "request": "join",
      "room": 1234,
      "ptype": "subscriber",
      "feed": feed,
    };
    subscriberHandles[feed].webRTCHandle.peerConnection.onAddStream =
        (stream) async {
      print('remote stream recieved');
        setState(() {
          remoteRenderers[feed] = new RTCVideoRenderer();
        });
        await remoteRenderers[feed].initialize();
        remoteRenderers[feed].srcObject = stream;

    };
    subscriberHandles[feed].webRTCHandle.peerConnection.onRemoveStream =
        (stream) async {

      print('remote stream recieved');
      print(stream.getTracks().length.toString() + ' Tracks Found!');

        setState(() {
          remoteRenderers[feed] = new RTCVideoRenderer();
        });
        await remoteRenderers[feed].initialize();
        remoteRenderers[feed].srcObject = stream;

    };
    await subscriberHandles[feed].send(data: register);
    subscriberHandles[feed].messages.listen((msg) async {
      print('subscriber event');
      print(msg);
      if (msg['janus'] == 'event') {
        if (msg['jsep'] != null) {
          await subscriberHandles[feed].handleRemoteJsep(msg['jsep']);
          var body = {"request": "start", "room": 1234};
          await subscriberHandles[feed].send(
              data: body,
              jsep: await subscriberHandles[feed].createAnswer(offerOptions:{
                "offerToReceiveAudio": false,
                "offerToReceiveVideo": false
              }));
        }
        var pluginData = msg['plugindata'];
        if (pluginData != null) {
          var data = pluginData['data'];
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
          RestJanusTransport(url: 'https://master-janus.onemandev.tech/rest');
      ws = WebSocketJanusTransport(
          url: 'wss://master-janus.onemandev.tech/websocket');
      j = JanusClient(transport: ws, iceServers: [
        RTCIceServer(
            url: "stun:stun.voip.eutelia.it:3478", username: "", credential: "")
      ]);
    });
    await j.createSession().then((value) {
      setState(() {
        session = value;
      });
    });

    print(session.sessionId);
    await session.attach(JanusPlugins.VIDEO_ROOM).then((value) {
      setState(() {
        plugin = value;
      });
    });
    print('got handleId');
    print(plugin.handleId);
    _localRenderer.srcObject = await plugin.initializeMediaDevices();

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

      if (msg['janus'] == 'event') {
        if (msg['jsep'] != null) {
          print('handling sdp');
          await plugin.handleRemoteJsep(msg['jsep']);
        }
        var pluginData = msg['plugindata'];
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
            if (data['videoroom'] == 'joined') {
              print('user joined configuring video stream');
              var publish = {"request": "publish", "bitrate": 20000};
              RTCSessionDescription offer = await plugin.createOffer(
                  offerToReceiveAudio: true, offerToReceiveVideo: true);
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
//                  -_localRenderer.
              }),
          IconButton(
              icon: Icon(
                Icons.call_end,
                color: Colors.red,
              ),
              onPressed: () {
                if (plugin != null) {
                  plugin.hangup();
                }

                if (_localRenderer.renderVideo) {
                  _localRenderer.srcObject = null;
                  _localRenderer.dispose();
                }
                remoteRenderers.entries.forEach((element) async {
                  // element.value.srcObject = null;
                  await element.value.dispose();
                  remoteRenderers.remove(element.key);

                });
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
      body:  GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,

        childAspectRatio: 1,
        crossAxisSpacing:30,
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
      )
    );
  }
}
