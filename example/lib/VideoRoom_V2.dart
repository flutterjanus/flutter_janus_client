import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

import 'package:janus_client_example/conf.dart';

class VideoRoomV2 extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<VideoRoomV2> {
  JanusClient j;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  Map<int, RTCVideoRenderer> remoteRenderers = {};
  RestJanusTransport rest;
  WebSocketJanusTransport ws;
  JanusSession session;
  JanusPlugin plugin;
  Map<int, JanusPlugin> subscriberHandles = {};
  int myId;

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
    var value = await session.attach(JanusPlugins.VIDEO_ROOM);
    setState(() {
      subscriberHandles[feed] = value;
    });

    var register = {
      "request": "join",
      "room": 1234,
      "ptype": "subscriber",
      "feed": feed,
    };
    subscriberHandles[feed].remoteStream.listen((stream) async {
      print('remote stream recieved');
      setState(() {
        remoteRenderers[feed] = new RTCVideoRenderer();
      });
      await remoteRenderers[feed].initialize();
      remoteRenderers[feed].srcObject = stream;
    });
    await subscriberHandles[feed].send(data: register);
    subscriberHandles[feed].messages.listen((msg) async {
      print('subscriber event');
      print(msg);
      if (msg.event['janus'] == 'event') {
        if (msg.jsep != null) {
          await subscriberHandles[feed].handleRemoteJsep(msg.jsep);
          var body = {"request": "start", "room": 1234};
          await subscriberHandles[feed].send(
              data: body,
              jsep: await subscriberHandles[feed].createAnswer(
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
    await initRenderers();
    setState(() {
      rest = RestJanusTransport(url: servermap['janus_rest']);
      ws = WebSocketJanusTransport(url: servermap['onemandev_master_ws']);
      j = JanusClient(transport: ws, iceServers: [
        RTCIceServer(
            url: "stun:stun1.l.google.com:19302", username: "", credential: "")
      ]);
    });
    var sess = await j.createSession();
    session = sess;
    plugin = await session.attach(JanusPlugins.VIDEO_ROOM);
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
    await remoteRenderers[0].initialize();
    setState(() {
      remoteRenderers[0].srcObject = stream;
    });

    var register = {
      "request": "join",
      "ptype": "publisher",
      "room": 1234,
      "display": "Shivansh" + randomString()
    };
    print('got response');
    print(await plugin.send(data: register));
    plugin.messages.listen((msg) async {
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
                data.containsKey('unpublished')) {
              print('recieved unpublishing event on subscriber handle');
              if (remoteRenderers.containsKey(data['unpublished'])) {
                if (remoteRenderers[data['unpublished']] != null) {
                  remoteRenderers[data['unpublished']].srcObject = null;
                  setState(() {
                    remoteRenderers.remove(data['unpublished']);
                  });
                  await remoteRenderers[data['unpublished']]?.dispose();
                }
              }
              if (subscriberHandles.containsKey(data['unpublished'])) {
                await subscriberHandles[data['unpublished']].dispose();
                subscriberHandles.remove(data['unpublishWiqed']);
              }

            }
            if (data['videoroom'] == 'joined') {
              print('user joined configuring video stream');
              myId = data['id'];
              var publish = {"request": "publish", "bitrate": 10000000};
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

    if (_localRenderer != null) {
      _localRenderer.srcObject = null;
      try {
        await _localRenderer?.dispose();
      } catch (e) {}
    }

    if (plugin != null) {
      plugin.dispose();
    }
    subscriberHandles.entries.forEach((element) async {
      if (element.value != null) {
        await element.value.hangup();
        await element.value.dispose();
        subscriberHandles.remove(element.key);
      }
    });
    remoteRenderers.entries.forEach((element) async {
      if (element.value != null) {
        element.value.srcObject = null;
        await element.value?.dispose();
        remoteRenderers.remove(element.key);
      }
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
                  if (plugin != null) {
                    plugin.switchCamera();
                  }
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
