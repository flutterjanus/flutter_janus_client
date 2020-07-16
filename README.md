# janus_client

It will allow you to connect to janus gateway server from your flutter application.
for implementing webrtc stack, flutter_webrtc plugin is used.

## under development
This plugin is under heavy development and lot of features present in janusjs library are still unimplemented.
If you want to help support this plugin development, then you are more than welcome.

# Sample
(sample image)[]

![sample image](https://github.com/shivanshtalwar0/flutter_janus_client/raw/master/samples/videoroom_2_participants.jpg)

## status
| Feature            | Support | Well Tested |
|--------------------|---------|-------------|
| WebSocket          | Yes     | No          |
| Rest/Http API      | No      | No          |
| Video Room Plugin  | Yes     | No          |
| Video Call Plugin  | Yes     | No          |
| Audio Call Plugin  | No      | No          |
| Sip Plugin         | No      | No          |
| Text Room Plugin   | No      | No          |

# Getting Started

    import 'dart:async';
    
    import 'package:flutter/cupertino.dart';
    import 'package:flutter/material.dart';
    import 'package:flutter_webrtc/webrtc.dart';
    import 'package:janus_client/Plugin.dart';
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
    final _remoteRenderer = new RTCVideoRenderer();
    
    class _MyAppState extends State<MyApp> {
      JanusClient j;
      Plugin pluginHandle;
      Plugin subscriberHandle;
      MediaStream remoteStream;
      MediaStream myStream;
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
                _remoteRenderer.mirror = true;
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
            'wss://janus.onemandev.tech/websocket',
            'http://104.45.152.100:55493/janus'
          ], withCredentials: true, apiSecret: "SecureIt");
          j.connect(onSuccess: () async {
            debugPrint('voilla! connection established');
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
          ),
        );
      }
    }


