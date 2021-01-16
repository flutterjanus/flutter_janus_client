import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/Plugin.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

import 'dart:async';

class SipCall extends StatefulWidget {
  @override
  _SipCallState createState() => _SipCallState();
}

class _SipCallState extends State<SipCall> {
  JanusClient j;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  Plugin pluginHandle;
  Plugin subscriberHandle;
  MediaStream remoteStream;
  MediaStream myStream;
  bool registered = false;

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
    await _remoteRenderer.initialize();
  }

  Future<void> initPlatformState() async {
    setState(() {
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
        'wss://janus.conf.meetecho.com/ws',
        'wss://janus.onemandev.tech/janus/websocket',
      ], withCredentials: true, apiSecret: "SecureIt");
      j.connect(onSuccess: (sessionId) async {
        debugPrint('voilla! connection established with session id as' +
            sessionId.toString());
        j.attach(Plugin(
            plugin: 'janus.plugin.sip',
            onMessage: (msg, jsep) async {
              print(msg);
              var error = msg['error'];
              if (error != null) {
                print('Not Registered');
                return;
              }
              var result = msg["result"];
              var event = result["event"];
              if (result != null && event != null) {
                if (jsep != null) {
                  debugPrint('handling jsep');
                  pluginHandle.handleRemoteJsep(jsep);
                }
                if (event == 'registered') {
                  registered = true;
                  print('Registered');
                }
              }
            },
            onRemoteStream: (stream) {
              _remoteRenderer.srcObject = stream;
              remoteStream = stream;
            },
            onSuccess: (plugin) async {
              setState(() {
                pluginHandle = plugin;
              });
              MediaStream stream = await plugin.initializeMediaDevices(
                  mediaConstraints: {"audio": true, "video": false});
              setState(() {
                myStream = stream;
              });
              setState(() {
                _localRenderer.srcObject = myStream;
              });
              register();
            }));
      }, onError: (e) {
        debugPrint('some error occured');
      });
    });
  }

  register() {
    try {
      // replace the [sip-username], [sip-server], [sip-displayname] with the actual data
      const register = {
        "username": "sip:[sip-username]@[sip-server]",
        "display_name": "[sip-displayname]",
        "secret": "SecureIt",
        "proxy": "sip:[sip-server]:5060",
        "sips": false,
        "request": 'register'
      };
      pluginHandle.send(message: register);
    } catch (e) {}
  }

  call(phone) async {
    try {
      RTCSessionDescription offer =
          await pluginHandle.createOffer(offerToReceiveVideo: false);
      // [sip-server] value need to be replaced
      var call = {"request": "call", "uri": "sip:" + phone + "@[sip-server]"};
      pluginHandle.send(message: call, jsep: offer);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: Icon(
                Icons.security,
                color: Colors.greenAccent,
              ),
              onPressed: () async {
                await this.initRenderers();
                await this.initPlatformState();
//                  -_localRenderer.
              }),
          IconButton(
              icon: Icon(
                Icons.call,
                color: Colors.greenAccent,
              ),
              onPressed: () async {
                if (this.registered) {
                  var phone = await prompt(context,
                      title: Text('Please enter the number you wish to call'),
                      textOK: Text('Call'),
                      textCancel: Text('Cancel'),
                      hintText: '0044xxxxxx',
                      autoFocus: true);
                  if (phone != null) {
                    this.call(phone);
                  }
                }
//
              }),
          IconButton(
              icon: Icon(
                Icons.call_end,
                color: Colors.red,
              ),
              onPressed: () {
                pluginHandle.hangup();
              }),
        ],
        title: const Text('janus_client'),
      ),
      body: Stack(children: [
        Positioned.directional(
          top: 5,
          start: 5,
          textDirection: TextDirection.ltr,
          child: RTCVideoView(
            _remoteRenderer,
          ),
        ),
      ]),
    );
  }
}
