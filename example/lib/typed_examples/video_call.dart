import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

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
  MediaStream? localStream;
  MediaStream? remoteVideoStream;
  MediaStream? remoteAudioStream;
  dynamic incomingDialog;
  dynamic registerDialog;
  dynamic callDialog;

  Future<void> localMediaSetup() async {
    await _localRenderer.initialize();
    MediaStream? temp = await publishVideo.initializeMediaDevices();
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

  openRegisterDialog() async {
    registerDialog = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            insetPadding: EdgeInsets.zero,
            title: Text("Register As"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: "Your Name"),
                      controller: nameController,
                      validator: (val) {
                        if (val == '') {
                          return 'username can\'t be empty! ';
                        }
                      },
                      onFieldSubmitted: (v) {
                        registerUser();
                      },
                    ),
                    Padding(padding: EdgeInsets.all(9)),
                    ElevatedButton(
                      onPressed: () {
                        registerUser();
                      },
                      child: Text("Proceed"),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  makeCallDialog() async {
    callDialog = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text("Call Registered User or wait for user to call you"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                      labelText: "Name Of Registered User to call"),
                  controller: nameController,
                ),
                ElevatedButton(
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
    j = JanusClient(
        transport: ws,
        iceServers: [
          RTCIceServer(
              urls: "stun:stun.voip.eutelia.it:3478",
              username: "",
              credential: "")
        ],
        isUnifiedPlan: true);
    session = await j.createSession();
    publishVideo = await session.attach<JanusVideoCallPlugin>();
    await _remoteVideoRenderer.initialize();
    MediaStream? tempVideo = await createLocalMediaStream('remoteVideoStream');
    setState(() {
      remoteVideoStream = tempVideo;
    });
    publishVideo.remoteTrack?.listen((event) async {
      if (event.track != null && event.flowing == true) {
        remoteVideoStream?.addTrack(event.track!);
        _remoteVideoRenderer.srcObject = remoteVideoStream;
        // this is done only for web since web api are muted by default for local tagged mediaStream
        if (kIsWeb) {
          _remoteVideoRenderer.muted = false;
        }
      }
    });
    publishVideo.typedMessages?.listen((even) async {
      Object data = even.event.plugindata?.data;
      if (data is VideoCallRegisteredEvent) {
        Navigator.of(context).pop();
        print(data.result?.username);
        nameController.clear();
        await makeCallDialog();
      }
      if (data is VideoCallIncomingCallEvent) {
        incomingDialog =
            await showIncomingCallDialog(data.result!.username!, even.jsep);
      }
      if (data is VideoCallAcceptedEvent) {
        Navigator.of(context).pop();
        Navigator.of(context, rootNavigator: true)
            .pop(callDialog);
      }
      if (data is VideoCallCallingEvent) {
        var dialog;
        dialog = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Calling the peer..'),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true)
                              .pop(dialog);
                          Navigator.of(context, rootNavigator: true)
                              .pop(callDialog);
                        },
                        child: Text('Okay'))
                  ],
                ));
      }
      if (data is VideoCallHangupEvent) {
        await destroy();
      }
      publishVideo.handleRemoteJsep(even.jsep);
    }, onError: (error) async {
      if (error is JanusError) {
        var dialog;
        dialog = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop(dialog);
                        nameController.clear();
                      },
                      child: Text('Okay'))
                ],
                title: Text('Whoops!'),
                content: Text(error.error),
              );
            });
      }
    });
    await openRegisterDialog();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initJanusClient();
  }

  GlobalKey<FormState> formKey = GlobalKey();

  Future<void> registerUser() async {
    if (formKey.currentState?.validate() == true) {
      await publishVideo.register(nameController.text);
    }
  }

  destroy() async {
    publishVideo.dispose();
    session.dispose();
    Navigator.of(context).pop();
  }

  Future<dynamic> showIncomingCallDialog(
      String caller, RTCSessionDescription? jsep) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Incoming call from ${caller}'),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    await localMediaSetup();
                    await publishVideo.handleRemoteJsep(jsep);
                    Navigator.of(context, rootNavigator: true)
                        .pop(incomingDialog);
                    Navigator.of(context, rootNavigator: true).pop(callDialog);
                    await publishVideo.acceptCall();
                  },
                  child: Text('Accept')),
              ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true)
                        .pop(incomingDialog);
                    Navigator.of(context, rootNavigator: true).pop(callDialog);
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
                    _remoteVideoRenderer,
                    mirror: true,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
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
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
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
                      destroy();
                    })),
            padding: EdgeInsets.all(10),
          ),
        )
      ]),
    );
  }

  Future<void> cleanUpWebRTCStuff() async {
    await stopAllTracksAndDispose(localStream);
    await stopAllTracksAndDispose(remoteAudioStream);
    await stopAllTracksAndDispose(remoteVideoStream);
    _localRenderer.srcObject = null;
    _remoteVideoRenderer.srcObject = null;
    _localRenderer.dispose();
    _remoteVideoRenderer.dispose();
  }

  @override
  void dispose() async {
    super.dispose();
    cleanUpWebRTCStuff();
  }
}
