import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

import '../Helper.dart';

class TypedVideoCallV2Example extends StatefulWidget {
  @override
  _VideoCallV2ExampleState createState() => _VideoCallV2ExampleState();
}

class _VideoCallV2ExampleState extends State<TypedVideoCallV2Example> {
  late JanusClient j;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusVideoCallPlugin publishVideo;
  TextEditingController nameController = TextEditingController();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteVideoRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteAudioRenderer = RTCVideoRenderer();
  MediaStream? localStream;
  MediaStream? remoteVideoStream;
  MediaStream? remoteAudioStream;

  Future<void> localMediaSetup() async {
    await _localRenderer.initialize();
    MediaStream? temp = await publishVideo.initializeMediaDevices(mediaConstraints: {"audio": true, "video": true});
    setState(() {
      localStream = temp;
    });
    _localRenderer.srcObject = localStream;
  }

  makeCall() async {
    await localMediaSetup();
    await publishVideo.call(nameController.text);
    nameController.text = "";
  }

  registerDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text("Register As"),
            content: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: "Your Name"),
                  controller: nameController,
                ),
                RaisedButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  onPressed: () {
                    registerUser(nameController.text);
                  },
                  child: Text("Proceed"),
                )
              ],
            ),
          );
        });
  }

  makeCallDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text("Call Registered User or wait for user to call you"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: "Name Of Registered User to call"),
                  controller: nameController,
                ),
                RaisedButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  onPressed: () {
                    makeCall();
                  },
                  child: Text("Call"),
                )
              ],
            ),
          );
        });
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await _localRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  initJanusClient() async {
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    j = JanusClient(transport: ws, iceServers: [RTCIceServer(urls: "stun:stun.voip.eutelia.it:3478", username: "", credential: "")], isUnifiedPlan: true);
    session = await j.createSession();
    publishVideo = await session.attach<JanusVideoCallPlugin>();
    await _remoteVideoRenderer.initialize();
    await _remoteAudioRenderer.initialize();
    MediaStream? tempVideo = await createLocalMediaStream('remoteVideoStream');
    setState(() {
      remoteVideoStream = tempVideo;
    });
    MediaStream? tempAudio = await createLocalMediaStream('remoteAudioStream');
    setState(() {
      remoteAudioStream = tempAudio;
    });
    publishVideo.remoteTrack?.listen((event) async {
      if (event.track != null && event.track?.kind == 'video' && event.flowing == true) {
        remoteVideoStream?.addTrack(event.track!);
        _remoteVideoRenderer.srcObject = remoteVideoStream;
      }
      if (event.track != null && event.track?.kind == 'audio' && event.flowing == true) {
        remoteAudioStream?.addTrack(event.track!);
        _remoteAudioRenderer.srcObject = remoteAudioStream;
      }
    });

    publishVideo.messages?.listen((even) async {
      print(even);
      var pluginData = even.event['plugindata'];
      if (pluginData != null) {
        var data = pluginData['data'];
        if (data != null) {
          var result = data["result"];
          if (result != null) {
            if (result["event"] != null) {
              var event = result["event"];
              if (event == 'registered') {
                Navigator.of(context).pop();
                nameController.clear();
                makeCallDialog();
              } else if (event == 'accepted') {
                var peer = result["username"];
                if (peer != null) {
                  debugPrint("Call started!");
                } else {}
                // Video call can start
                if (even.jsep != null) {
                  publishVideo.handleRemoteJsep(even.jsep!);
                  Navigator.of(context).pop();
                }
              } else if (event == 'incomingcall') {
                debugPrint("Incoming call from " + result["username"] + "!");
                var caller = result["username"];
                await showIncomingCallDialog(caller, even);
              } else if (event == 'hangup') {
                await destroy();
              }
            }
          }
        }
      }
    });
    await registerDialog();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initJanusClient();
  }

  Future<void> registerUser(userName) async {
    await publishVideo.register(userName);
  }

  destroy() async {
    publishVideo.dispose();
    session.dispose();
    Navigator.of(context).pop();
  }

  Future<dynamic> showIncomingCallDialog(String caller, EventMessage event) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Incoming call from ${caller}'),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    await localMediaSetup();
                    if (event.jsep != null) {
                      await publishVideo.handleRemoteJsep(event.jsep);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }
                    // Notify user
                    await publishVideo.acceptCall();
                  },
                  child: Text('Accept')),
              ElevatedButton(
                  onPressed: () async {
                    await publishVideo.hangup();
                  },
                  child: Text('Reject')),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  RTCVideoView(
                    _remoteAudioRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
                  RTCVideoView(
                    _remoteVideoRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  )
                ],
              ),
            ),
            Expanded(
                flex: 1,
                child: Container(
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
                ))
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            child: IconButton(
                icon: Icon(Icons.refresh),
                color: Colors.white,
                onPressed: () {
                  publishVideo.switchCamera();
                }),
            padding: EdgeInsets.all(25),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 30,
                child: IconButton(
                    icon: Icon(Icons.call_end),
                    color: Colors.white,
                    onPressed: () async {
                      await publishVideo.hangup();
                      await destroy();
                    })),
            padding: EdgeInsets.all(10),
          ),
        )
      ]),
    );
  }

  cleanUpWebRTCStuff() async {
    await stopAllTracksAndDispose(localStream);
    await stopAllTracksAndDispose(remoteAudioStream);
    await stopAllTracksAndDispose(remoteVideoStream);
    _localRenderer.srcObject = null;
    _remoteVideoRenderer.srcObject = null;
    _remoteAudioRenderer.srcObject = null;
    _remoteAudioRenderer.dispose();
    _localRenderer.dispose();
    _remoteVideoRenderer.dispose();
  }

  @override
  void dispose() async {
    super.dispose();
    cleanUpWebRTCStuff();
  }
}
