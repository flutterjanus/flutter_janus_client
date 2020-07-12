import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/rtc_peerconnection.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:janus_client/Plugin.dart';
import 'package:janus_client/janus_client.dart';
import 'package:janus_client/utils.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

final _localRenderer = new RTCVideoRenderer();

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initRenderers();
    initPlatformState();
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    JanusClient j = JanusClient(iceServers: [
      RTCIceServer()
    ], server: [
      'wss://janus.onemandev.tech/websocket',
      'http://104.45.152.100:55493/janus'
    ], withCredentials: true, apiSecret: "SecureIt");
    j.connect(onSuccess: () {
      debugPrint('voilla! connection established');
      j.attach(Plugin(
        plugin: 'janus.plugin.videoroom',
        onSuccess: (pluginHandle) async {
          print(pluginHandle);
          var register = {
            "request": "join",
            "room": 1234,
            "ptype": "publisher",
            "display": 'shivansh'
          };
          Uuid uuid = Uuid();
          var transaction = uuid.v4();
//          var request = {
//            "janus": "message",
//            "body": register,
//            "transaction": transaction
//          };
          pluginHandle.send(
              message: register,
              onSuccess: () async {
                print('fuck it works');

//                keep session live dude!
                Timer.periodic(Duration(seconds: 5), (timer) {
                  pluginHandle.webSocketChannel.sink.add(stringify({
                    "janus": "keepalive",
                    "session_id": pluginHandle.sessionId,
                    "transaction": "sBJNyUhH6Vc6",
                    "apisecret": pluginHandle.apiSecret
                  }));
                });

                Map<String, dynamic> configuration = {
                  "iceServers": [
                    {
                      "url": "stun:104.45.152.100:3478",
                      "username": "onemandev",
                      "credential": "SecureIt"
                    },
                    {
                      "url": "turn:104.45.152.100:3478",
                      "username": "onemandev",
                      "credential": "SecureIt"
                    },
                  ]
                };

                final Map<String, dynamic> offerSdpConstraints = {};
                RTCPeerConnection peerConnection = await createPeerConnection(
                    configuration, offerSdpConstraints);
//                peerConnection.

                final Map<String, dynamic> mediaConstraints = {
                  "audio": true,
                  "video": {
                    "mandatory": {
                      "minWidth":
                          '1280', // Provide your own width, height and frame rate here
                      "minHeight": '720',
                      "minFrameRate": '60',
                    },
                    "facingMode": "user",
                    "optional": [],
                  }
                };
                MediaStream mediaStream =
                    await navigator.getUserMedia(mediaConstraints);
                setState(() {
                  _localRenderer.srcObject = mediaStream;
                });
                peerConnection.addStream(mediaStream);
                RTCSessionDescription offer = await peerConnection.createOffer(
                    {"offerToReceiveAudio": true, "offerToReceiveVideo": true});
                peerConnection.setLocalDescription(offer);
                var publish = {
                  "request": "configure",
                  "audio": true,
                  "video": true,
                  "bitrate": 20000000
                };
                pluginHandle.send(
                    message: publish,
                    jsep: offer,
                    onSuccess: () async {
                      print("trash here");

                      var data = parse(await pluginHandle.webSocketStream.stream
                          .firstWhere(
                              (element) => parse(element)["janus"] == "event"));
                      print(data["jsep"]);
                      peerConnection.setRemoteDescription(RTCSessionDescription(
                          data["jsep"]["sdp"], data["jsep"]["type"]));
                      peerConnection.onIceCandidate =
                          (RTCIceCandidate candidate) {
                        print(candidate);
                        Map<dynamic, dynamic> request = {
                          "janus": "trickle",
                          "candidate": candidate.toMap(),
                          "transaction": "sendtrickle"
                        };
                        request["session_id"] = pluginHandle.sessionId;
                        request["handle_id"] = pluginHandle.handleId;
                        request["apisecret"] = "SecureIt";
                        pluginHandle.webSocketChannel.sink
                            .add(stringify(request));

//
                      };
                      pluginHandle.webSocketStream.stream.listen((event) {
                        dynamic data = parse(event);
                        if (data["janus"] == "trickle") {
                          Map<dynamic, dynamic> candidate = data["candidate"];
                          if (candidate.containsKey("sdpMid") &&
                              candidate.containsKey("sdpMLineIndex")) {
                            peerConnection.addCandidate(RTCIceCandidate(
                                candidate["candidate"],
                                candidate["sdpMid"],
                                candidate["sdpMLineIndex"]));
                          }
                        }
                      });
//                      print(await peerConnection.getRemoteStreams());
                      peerConnection.onIceConnectionState =
                          (RTCIceConnectionState s) {
                        print('got state');
                        print(s.toString());
                      };
                    });
              },
              onError: (e) {
                print(e);
              });

//          peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
//            print('onCandidate: ' + candidate.candidate);
//            peerConnection.addCandidate(candidate);
//      setState(() {
//        _sdp += '\n';
//        _sdp += candidate.candidate;
//      });
//          }
//          peerConnection.createDataChannel("datachannel", rtcDataChannelInit);
//          peerConnection.onDataChannel = (datachannel) {
//            print(datachannel.state);
//            datachannel.onMessage = (msg) {
//              print(msg.text);
//            };
//            datachannel.send(RTCDataChannelMessage(stringify(request)));
//          };
//          peerConnection.onIceConnectionState = (conn) {
//            print(conn);
//          };

//          RTCSessionDescription description =
//              await peerConnection.createOffer(offerSdpConstraints);
//          print(description.sdp);
//          peerConnection.setLocalDescription(description);
//          pluginHandle.send(message: request);
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
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: RTCVideoView(_localRenderer)),
        ),
      ),
    );
  }
}
