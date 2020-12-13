import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/Plugin.dart';

import 'dart:async';
class VideoRoom extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<VideoRoom> {
  JanusClient j;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  Plugin pluginHandle;
  Plugin subscriberHandle;
  MediaStream remoteStream;
  MediaStream myStream;

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

  _newRemoteFeed(JanusClient j, feed) async {
    print('remote plugin attached');
    j.attach(Plugin(
        plugin: 'janus.plugin.videoroom',
        onMessage: (msg, jsep) async {
          if (jsep != null) {
            await subscriberHandle.handleRemoteJsep(jsep);
            var body = {"request": "start", "room": 1234};

            await subscriberHandle.send(
                message: body,
                jsep: await subscriberHandle.createAnswer(),
                onSuccess: () {});
          }
        },
        onSuccess: (plugin) {
          setState(() {
            subscriberHandle = plugin;
          });
          var register = {
            "request": "join",
            "room": 1234,
            "ptype": "subscriber",
            "feed": feed,
//            "private_id": 12535
          };
          subscriberHandle.send(message: register, onSuccess: () async {});
        },
        onRemoteStream: (stream) {
          print('got remote stream');
          setState(() {
            remoteStream = stream;
            _remoteRenderer.srcObject = remoteStream;
          });
        }));
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
        'https://janus.conf.meetecho.com/janus',
        'https://janus.onemandev.tech/janus',
        // 'wss://janus.onemandev.tech/janus/websocket',
        // 'https://janus.onemandev.tech/janus',

      ], withCredentials: true, apiSecret: "SecureIt");
      j.connect(onSuccess: (sessionId) async {
        debugPrint('voilla! connection established with session id as' +
            sessionId.toString());
        Map<String, dynamic> configuration = {
          "iceServers": j.iceServers.map((e) => e.toMap()).toList()
        };

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
                j.destroy();
                pluginHandle.hangup();
                subscriberHandle.hangup();
                _localRenderer.srcObject = null;
                _localRenderer.dispose();
                _remoteRenderer.srcObject = null;
                _remoteRenderer.dispose();
                setState(() {
                  pluginHandle = null;
                  subscriberHandle = null;
                });
              }),
          IconButton(
              icon: Icon(
                Icons.switch_camera,
                color: Colors.white,
              ),
              onPressed: () {
                if (pluginHandle != null) {
                  pluginHandle.switchCamera();
                }
              })
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
    );
  }
}
