import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/rtc_data_channel.dart';
import 'package:janus_client/Plugin.dart';
import 'package:janus_client/janus_client.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    JanusClient j = JanusClient(server: [
      'ws://104.45.152.100:37457',
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
            "room": 1234567,
            "ptype": "publisher",
            "display": 'shivansh'
          };
          Uuid uuid = Uuid();
          var transaction = uuid.v4();
          var request = {
            "janus": "message",
            "body": register,
            "transaction": transaction
          };
          pluginHandle.send(
              message: register,
              onSuccess: () {
                print('fuck it works');
              },
              onError: (e) {
                print(e);
              });
          Map<String, dynamic> configuration = {
            "iceServers": [
              {
                "url": "stun:onemandev.tech:3478",
                "username": "onemandev",
                "credential": "SecureIt"
              },
              {
                "url": "turn:onemandev.tech:3478",
                "username": "onemandev",
                "credential": "SecureIt"
              },
            ]
          };

          final Map<String, dynamic> offerSdpConstraints = {
            "mandatory": {
              "OfferToReceiveAudio": false,
              "OfferToReceiveVideo": false,
            },
            "optional": [],
          };
          RTCDataChannelInit rtcDataChannelInit = RTCDataChannelInit();
          rtcDataChannelInit.id = 1;
          rtcDataChannelInit.ordered = true;
          rtcDataChannelInit.maxRetransmitTime = -1;
          rtcDataChannelInit.maxRetransmits = -1;
          rtcDataChannelInit.protocol = "sctp";
          rtcDataChannelInit.negotiated = false;
//          RTCPeerConnection peerConnection =
//              await createPeerConnection(configuration, offerSdpConstraints);
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
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
