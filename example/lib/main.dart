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
//    initPlatformState();
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
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
        onWebRTCState: (state, reason) {
          print("fuck onwebrtc state");
          print(state.toString() + reason.toString());
        },

//        onMessage: (msg, jsep) async {
//          if (jsep != null) {
//            await pluginHandle.webRTCHandle.pc.setRemoteDescription(
//                RTCSessionDescription(jsep["sdp"], jsep["type"]));
//          }
//        },
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
          await pluginHandle.switchCamera();
          var register = {
            "request": "join",
            "room": 1234,
            "ptype": "publisher",
            "display": 'shivansh'
          };
          pluginHandle.send(
              message: register,
              onSuccess: () async {
                print('fuck it works');
//                Map<String, dynamic> configuration = {
//                  "iceServers": [
//                    {
//                      "url": "stun:40.85.216.95:3478",
//                      "username": "onemandev",
//                      "credential": "SecureIt"
//                    },
//                    {
//                      "url": "turn:40.85.216.95:3478",
//                      "username": "onemandev",
//                      "credential": "SecureIt"
//                    },
//                  ]
//                };
//
//                final Map<String, dynamic> offerSdpConstraints = {};
//                RTCPeerConnection peerConnection = await createPeerConnection(
//                    configuration, offerSdpConstraints);

//                peerConnection.

//                final Map<String, dynamic> mediaConstraints = {
//                  "audio": true,
//                  "video": {
//                    "mandatory": {
//                      "minWidth":
//                          '1280', // Provide your own width, height and frame rate here
//                      "minHeight": '720',
//                      "minFrameRate": '60',
//                    },
//                    "facingMode": "user",
//                    "optional": [],
//                  }
//                };
//                MediaStream mediaStream =
//                    await navigator.getUserMedia(mediaConstraints);
//                setState(() {
//                  _localRenderer.srcObject = mediaStream;
//                  _localRenderer.mirror = true;
//                });
//                await mediaStream
//                    .getVideoTracks()
//                    .firstWhere((track) => track.kind == "video")
//                    .switchCamera();
//                await peerConnection.addStream(mediaStream);

//                peerConnection.onIceConnectionState =
//                    (RTCIceConnectionState s) {
//                  print('got state');
//                  print(s.toString());
//                };
//                RTCSessionDescription offer = await peerConnection.createOffer(
//                    {"offerToReceiveAudio": true, "offerToReceiveVideo": true});
//                await peerConnection.setLocalDescription(offer);
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
                      print("trash here");
                      pluginHandle.webSocketStream.listen((event) async {
                        print('bottom hook worked for some event');
                        Map<String, dynamic> data = parse(event);
                        if (data.containsKey("janus")) {
                          if (data["janus"] == "event" &&
                              data.containsKey("jsep")) {
                            print('trash2');
                            await pluginHandle.webRTCHandle.pc
                                .setRemoteDescription(RTCSessionDescription(
                                    data["jsep"]["sdp"], data["jsep"]["type"]));
                          }

//                          if (data["janus"] == "trickle") {
//                            print('got trickle');
//                            print(data["candidate"]);
//                            Map<dynamic, dynamic> candidate = data["candidate"];
//                            if (candidate.containsKey("sdpMid") &&
//                                candidate.containsKey("sdpMLineIndex")) {
//                              await j.webRTCHandle.pc.addCandidate(
//                                  RTCIceCandidate(
//                                      candidate["candidate"],
//                                      candidate["sdpMid"],
//                                      candidate["sdpMLineIndex"]));
//                            }
//                          }
                        }
                      });

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
                  this.pluginHandle.send(message: {"request": "leave"});
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
