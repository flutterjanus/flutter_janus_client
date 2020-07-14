import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:janus_client/Plugin.dart';
import 'package:janus_client/PluginHandle.dart';
import 'package:janus_client/janus_client.dart';
import 'package:janus_client/utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

final _localRenderer = new RTCVideoRenderer();

class _MyAppState extends State<MyApp> {
  JanusClient j;
  PluginHandle pluginHandle;

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await initPlatformState();
  }

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> initPlatformState() async {
    j = JanusClient(iceServers: [
      RTCIceServer(
          url: "stun:40.85.216.95:3478",
          username: "onemandev",
          credential: "SecureIt"),
      RTCIceServer(
          url: "turn:40.85.216.95:3478",
          username: "onemandev",
          credential: "SecureIt")
    ], server: [
      'wss://janus.onemandev.tech/websocket',
      'http://104.45.152.100:55493/janus'
    ], withCredentials: true, apiSecret: "SecureIt");
    j.connect(onSuccess: () {
      debugPrint('voilla! connection established');
      j.attach(Plugin(
        plugin: 'janus.plugin.videoroom',
        onWebRTCState: (bool state, reason) {
          print("Webrtc state " + (state ? "UP" : "Down"));
        },
        onDestroy: () {
          _localRenderer.srcObject = null;
        },
        onMessage: (msg, jsep) async {
          print('on message hook called');
          if (jsep != null) {
            pluginHandle.handleRemoteJsep(jsep);
          }
        },
        onSuccess: (pluginHandle) async {
          setState(() {
            this.pluginHandle = pluginHandle;
          });
          print(pluginHandle);
          MediaStream myStream = await pluginHandle.initializeMediaDevices();
          setState(() {
            _localRenderer.srcObject = myStream;
            _localRenderer.mirror = true;
          });
          var register = {
            "request": "join",
            "room": 1234,
            "ptype": "publisher",
            "display": 'shivansh'
          };
          pluginHandle.send(
              message: register,
              onSuccess: () async {
                RTCSessionDescription offer = await pluginHandle.createOffer();
                var publish = {
                  "request": "configure",
                  "audio": true,
                  "video": true,
                  "bitrate": 90000000
                };
                pluginHandle.send(
                    message: publish,
                    jsep: offer,
                    onSuccess: () async {
                      pluginHandle.webRTCHandle.pc.onIceCandidate =
                          (RTCIceCandidate candidate) {
//                        print(candidate);
                        debugPrint('sending trickle');
                        Map<dynamic, dynamic> request = {
                          "janus": "trickle",
                          "candidate": candidate.toMap(),
                          "transaction": "sendtrickle"
                        };
                        request["session_id"] = pluginHandle.sessionId;
                        request["handle_id"] = pluginHandle.handleId;
                        request["apisecret"] = "SecureIt";
                        pluginHandle.webSocketSink.add(stringify(request));
                      };
                    });
              },
              onError: (e) {
                print(e);
              });
        },
      ));
    }, onError: (e) {
      debugPrint('some error occured');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                icon: Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                onPressed: () {
                  pluginHandle.hangup();
                }),
            IconButton(
                icon: Icon(
                  Icons.switch_camera,
                  color: Colors.white,
                ),
                onPressed: () {
                  this.pluginHandle.switchCamera();
                })
          ],
          title: const Text('Plugin example app'),
        ),
        body: Center(child: RTCVideoView(_localRenderer)),
      ),
    );
  }
}
