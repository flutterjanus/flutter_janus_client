import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/Plugin.dart';

import 'dart:async';

class VideoRoom extends StatefulWidget {
  List<RTCVideoView> remote_videos = new List();
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<VideoRoom> {
  JanusClient j;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  List<RTCVideoRenderer> _remoteRenderer = new List<RTCVideoRenderer>();
  Plugin pluginHandle;
  Plugin subscriberHandle;
  List<MediaStream> remoteStream = new List<MediaStream>();
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
    int count = 0;
    while (count < 4) {
      _remoteRenderer.add(new RTCVideoRenderer());
      count++;
    }
    await _localRenderer.initialize();
    for (var renderer in _remoteRenderer) {
      await renderer.initialize();
    }
    count = 0;
    while (count < 4) {
      createLocalMediaStream("local").then((value) => remoteStream.add(value));
      count++;
    }
  }

  _newRemoteFeed(JanusClient j, List<Map> feeds) async {
    List<Map> myFeeds = feeds;
    print('remote plugin attached');
    j.attach(Plugin(
        plugin: 'janus.plugin.videoroom',
        onMessage: (msg, jsep) async {
          if (jsep != null) {
            await subscriberHandle.handleRemoteJsep(jsep);
            // var body = {"request": "start", "room": 2157};
            var body = {
              "request": "start",
              "room": 1234,
            };
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
            "streams": feeds,
          };
          print("Requesting to subscribe to publishers...");
          subscriberHandle.send(message: register, onSuccess: () async {});
        },
        onRemoteTrack: (stream, track, mid, on) {
          print('got remote track with mid=$mid');
          setState(() {
            if ((track as MediaStreamTrack).kind == "video" && on == true) {
              if (num.tryParse(mid).toInt() < 4) {
                remoteStream
                    .elementAt(num.tryParse(mid).toInt())
                    .addTrack(track, addToNative: true);
                print('added track to stream locally');
                _remoteRenderer
                        .elementAt(num.tryParse(mid as String).toInt())
                        .srcObject =
                    remoteStream.elementAt(num.tryParse(mid).toInt());
              }
            }
          });
        }));
  }

  Future<void> initPlatformState() async {
    setState(() {
      j = JanusClient(iceServers: [
        RTCIceServer(
            url: "turn:40.85.216.95:3478",
            username: "onemandev",
            credential: "SecureIt"),
      ], server: [
        'https://janus.onemandev.tech/janus',
      ], withCredentials: true, isUnifiedPlan: true);
      j.connect(onSuccess: (sessionId) async {
        debugPrint('voilla! connection established with session id as' +
            sessionId.toString());
        Map<String, dynamic> configuration = {
          "iceServers": j.iceServers.map((e) => e.toMap()).toList()
        };

        j.attach(Plugin(
            opaqueId: "videoroom_user",
            plugin: 'janus.plugin.videoroom',
            onMessage: (msg, jsep) async {
              print('publisheronmsg');
              if (msg["publishers"] != null) {
                var list = msg["publishers"];
                print('got publihers');
                print(list);
                List<Map> subscription = new List<Map>();
                //    _newRemoteFeed(j, list[0]["id"]);
                final filtereList = List.from(list);
                filtereList.forEach((item) => {
                      subscription.add({
                        "feed": LinkedHashMap.of(item).remove("id"),
                        "mid": "1"
                      })
                    });
                //Map.from(item)..forEach((key, value) => if(key != ("id")) ));
                _newRemoteFeed(j, subscription);
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
                "display": 'User test'
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
                _remoteRenderer.map((e) => e.srcObject = null);
                _remoteRenderer.map((e) => e.dispose());
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
      body: Row(children: [
        Expanded(
            child: (_remoteRenderer != null &&
                    _remoteRenderer.elementAt(0) != null)
                ? RTCVideoView(_remoteRenderer.elementAt(0))
                : Text(
                    "Waiting...",
                    style: TextStyle(color: Colors.black),
                  )),
        Expanded(
            child: (_remoteRenderer != null &&
                    _remoteRenderer.elementAt(1) != null)
                ? RTCVideoView(_remoteRenderer.elementAt(1))
                : Text(
                    "Waiting...",
                    style: TextStyle(color: Colors.black),
                  )),
        Expanded(
            child: (_remoteRenderer != null &&
                    _remoteRenderer.elementAt(2) != null)
                ? RTCVideoView(_remoteRenderer.elementAt(2))
                : Text(
                    "Waiting...",
                    style: TextStyle(color: Colors.black),
                  )),
        Expanded(
            child: (_remoteRenderer != null &&
                    _remoteRenderer.elementAt(3) != null)
                ? RTCVideoView(_remoteRenderer.elementAt(3))
                : Text(
                    "Waiting...",
                    style: TextStyle(color: Colors.black),
                  )),
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
