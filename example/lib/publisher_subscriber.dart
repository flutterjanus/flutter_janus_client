import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:janus_client/Plugin.dart';
import 'package:janus_client/janus_client_experimental.dart';
import 'package:janus_client/utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

final _localRenderer = new RTCVideoRenderer();
final _remoteRenderer = new RTCVideoRenderer();

class _MyAppState extends State<MyApp> {
  JanusClientExperimental j;
  Plugin pluginHandle;
  Plugin subscriberHandle;
  MediaStream remoteStream;
  MediaStream myStream;
  RTCPeerConnection subscriberPc;

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
    await _remoteRenderer.initialize();
  }

  _newRemoteFeed(JanusClientExperimental j, feed) async {
    print('remote plugin attached');
    j.attach(Plugin(
        plugin: 'janus.plugin.videoroom',
        onMessage: (msg, jsep) async {
          if (jsep != null) {
            await subscriberPc.setRemoteDescription(
                RTCSessionDescription(jsep["sdp"], jsep["type"]));
            RTCSessionDescription offer = await subscriberPc.createAnswer(
                {"offerToReceiveAudio": false, "offerToReceiveVideo": false});
            await subscriberPc.setLocalDescription(offer);
            var body = {"request": "start", "room": 1234};
            subscriberHandle.send(
                message: body,
                jsep: offer,
                onSuccess: () {
                  subscriberPc.onIceCandidate = (RTCIceCandidate candidate) {
//                        print(candidate);
                    debugPrint('remote sending trickle');
                    Map<dynamic, dynamic> request = {
                      "janus": "trickle",
                      "candidate": candidate.toMap(),
                      "transaction": "sendtrickle"
                    };
                    request["session_id"] = subscriberHandle.sessionId;
                    request["handle_id"] = subscriberHandle.handleId;
                    request["apisecret"] = "SecureIt";
                    subscriberHandle.webSocketSink.add(stringify(request));
                  };
                });
          }
          if (msg["janus"] == "trickle") {
            var candidate = msg["candidate"];
            if (candidate.containsKey("sdpMid") &&
                candidate.containsKey("sdpMLineIndex")) {
              subscriberPc.addCandidate(RTCIceCandidate(candidate["candidate"],
                  candidate["sdpMid"], candidate["sdpMLineIndex"]));
            }
          }
        },
        onSuccess: (plugin) {
          subscriberHandle = plugin;
          var register = {
            "request": "join",
            "room": 1234,
            "ptype": "subscriber",
            "feed": feed,
//            "private_id": 12535
          };
          subscriberPc.onAddStream = (stream) {
            print('got remote stream');
            setState(() {
              remoteStream = stream;
              _remoteRenderer.srcObject = remoteStream;
            });
          };
          subscriberHandle.send(message: register, onSuccess: () async {});
        }));
  }

  Future<void> initPlatformState() async {
    setState(() {
      j = JanusClientExperimental(iceServers: [
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
      j.connect(onSuccess: () async {
        debugPrint('voilla! connection established');
        Map<String, dynamic> configuration = {
          "iceServers": j.iceServers.map((e) => e.toMap()).toList()
        };

        RTCPeerConnection subscriberP =
            await createPeerConnection(configuration, {});
        setState(() {
          subscriberPc = subscriberP;
        });

        j.attach(Plugin(
            plugin: 'janus.plugin.videoroom',
            onMessage: (msg, jsep) async {
              print('publisheronmsg');
              if (msg["publishers"] != null) {
                var list = msg["publishers"];
                print('got publihers');
                print(list);
                _newRemoteFeed(j, list[0]["id"]);
              }

              if (jsep != null) {
//              print('got jsep');
                pluginHandle.handleRemoteJsep(jsep);
              }
            },
            onSuccess: (plugin) async {
              setState(() {
                pluginHandle = plugin;
              });
              MediaStream stream = await plugin.initializeMediaDevices();
              setState(() {
                myStream = stream;
              });
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
              plugin.send(
                  message: register,
                  onSuccess: () async {
                    var publish = {
                      "request": "configure",
                      "audio": true,
                      "video": true,
                      "bitrate": 2000000
                    };
                    RTCSessionDescription offer = await plugin.createOffer();
                    plugin.send(
                        message: publish, jsep: offer, onSuccess: () {});
                  });
            }));
      }, onError: (e) {
        debugPrint('some error occured');
      });
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
                onPressed: () {})
          ],
          title: const Text('janus_client'),
        ),
        body: Stack(children: [
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer,
            ),
          ),
          Align(
            child: Container(
              child: RTCVideoView(
                _localRenderer,
              ),
              height: 200,
              width: 200,
            ),
            alignment: Alignment.bottomRight,
          )
        ]),
      ),
    );
  }
}
