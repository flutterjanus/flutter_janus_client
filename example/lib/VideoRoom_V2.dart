import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
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
  Map<int, RTCVideoRenderer> remoteRenderers = {};
  Plugin pluginHandle;
  Map<int, Plugin> subscriberHandles = {};
  MediaStream myStream;

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    RestJanusTransport rest =
    RestJanusTransport(url: 'https://master-janus.onemandev.tech/rest');
    WebSocketJanusTransport ws = WebSocketJanusTransport(
        url: 'wss://master-janus.onemandev.tech/websocket');
    JanusClient j = JanusClient(transport: ws);
    JanusSession session = await j.createSession();
    print(session.sessionId);
    JanusPlugin plugin = await session.attach(JanusPlugins.VIDEO_ROOM);
    print('got handleId');
    print(plugin.handleId);
    var register = {
      "request": "join",
      "ptype": "publisher",
      "room": 1234,
      "display": "Shivansh"
    };
    print('got response');
    print(await plugin.send(data: register));
    plugin.messages.listen((msg)async {
      print('on message');

      if (msg['janus'] == 'event') {
        var pluginData = msg['plugindata'];
        if (pluginData != null) {
          var data = pluginData['data'];
          if (data != null) {
            if (data["publishers"] != null) {
              List<dynamic> list = data["publishers"];
              print('got publihers');
              print(list);
              // list.forEach((element) {
              //   _newRemoteFeed(element['id']);
              // });
            }
            if (data['videoroom'] == 'joined') {
              print('user joined configuring video stream');
              var publish = {"request": "publish", "bitrate": 200000};
              // RTCSessionDescription offer =
              //     await pluginHandle.createOffer(
              //     offerToReceiveAudio: true,
              //     offerToReceiveVideo: true);
              // await plugin.send(
              //     data: publish, jsep: offer);
            }
          }
        }
      }
    });


  }

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  initRenderers() async {
    await _localRenderer.initialize();
  }

  _newRemoteFeed(feed) async {
//     setState(() {
//       remoteRenderers[feed] = new RTCVideoRenderer();
//     });
//     await remoteRenderers[feed].initialize();
//     print('remote plugin attached');
//     j.attach(Plugin(
//         plugin: 'janus.plugin.videoroom',
//         onMessage: (msg, jsep) async {
//           if (msg['janus'] == 'event') {
//             var pluginData = msg['plugindata'];
//             if (pluginData != null) {
//               var data = pluginData['data'];
//               if (data != null) {
//                 if (data['videoroom'] == 'joined') {
//                   print('setting subscriber loop');
//                   var body = {"request": "start", "room": 1234};
//                   await subscriberHandles[feed].send(
//                       message: body,
//                       jsep: await subscriberHandles[feed].createAnswer(),
//                       onSuccess: () {});
//                 }
//               }
//             }
//           }
//
//           if (jsep != null) {
//             await subscriberHandles[feed].handleRemoteJsep(jsep);
//           }
//         },
//         onSuccess: (plugin) async {
//           setState(() {
//             subscriberHandles.putIfAbsent(feed, () => plugin);
//           });
//           var register = {
//             "request": "join",
//             "room": 1234,
//             "ptype": "subscriber",
//             "feed": feed,
// //            "private_id": 12535
//           };
//           await subscriberHandles[feed]
//               .send(message: register);
//         },
//         onRemoteStream: (stream) {
//           print('got remote stream');
//           setState(() {
//             remoteRenderers[feed].srcObject = stream;
//           });
//         }));
  }

  Future<void> initPlatformState() async {
    // setState(() {
    //   j = JanusClient(
    //       iceServers: [
    //         RTCIceServer(
    //             url: "stun:stun.voip.eutelia.it:3478",
    //             username: "",
    //             credential: "")
    //       ],
    //       server: servers,
    //       withCredentials: true,
    //       apiSecret: "SecureIt",
    //       isUnifiedPlan: false);
    //   j.connect(onSuccess: (sessionId) async {
    //     debugPrint('voilla! connection established with session id as' +
    //         sessionId.toString());
    //     j.attach(Plugin(
    //         plugin: 'janus.plugin.videoroom',
    //         onMessage: (msg, jsep) async {
    //           print('publisher onMessage');
    //           print(msg);
    //           if (msg['janus'] == 'event') {
    //             var pluginData = msg['plugindata'];
    //             if (pluginData != null) {
    //               var data = pluginData['data'];
    //               if (data != null) {
    //                 if (data["publishers"] != null) {
    //                   List<dynamic> list = data["publishers"];
    //                   print('got publihers');
    //                   print(list);
    //                   list.forEach((element) {
    //                     _newRemoteFeed(element['id']);
    //                   });
    //
    //
    //                 }
    //                 if (data['videoroom'] == 'joined') {
    //                   print('user joined configuring video stream');
    //                   var publish = {"request": "publish", "bitrate": 200000};
    //                   RTCSessionDescription offer =
    //                   await pluginHandle.createOffer(
    //                       offerToReceiveAudio: true,
    //                       offerToReceiveVideo: true);
    //                   await pluginHandle.send(
    //                       message: publish, jsep: offer);
    //                 }
    //               }
    //             }
    //           }
    //
    //           if (jsep != null) {
    //             print('handling sdp');
    //             await pluginHandle.handleRemoteJsep(jsep);
    //           }
    //         },
    //         onSuccess: (plugin) async {
    //           print('plugin created');
    //           setState(() {
    //             pluginHandle = plugin;
    //           });
    //           MediaStream stream = await plugin.initializeMediaDevices();
    //           setState(() {
    //             myStream = stream;
    //           });
    //           setState(() {
    //             _localRenderer.srcObject = myStream;
    //           });
    //           var register = {
    //             "request": "join",
    //             "ptype": "publisher",
    //             "room": 1234,
    //             "display": "Shivansh"
    //           };
    //           await plugin.send(
    //               message: register);
    //         }));
    //   }, onError: (e) {
    //     debugPrint('some error occured');
    //   });
    // });
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
                if (pluginHandle != null) {
                  pluginHandle.hangup();
                }
                // if (subscriberHandle != null) {
                //   subscriberHandle.hangup();
                // }
                _localRenderer.srcObject = null;
                _localRenderer.dispose();
                // _remoteRenderer.srcObject = null;
                // _remoteRenderer.dispose();
                // j.destroy();
                // setState(() {
                //   pluginHandle = null;
                //   subscriberHandle = null;
                // });
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
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 16 / 4,
          children: [
            RTCVideoView(
              _localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            ...remoteRenderers.entries.map((e){
              return RTCVideoView(
                e.value,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              );
            }).toList()
          ],
        )
      ]),
    );
  }
}
