import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';
import 'package:permission_handler/permission_handler.dart';

class TypedVideoCallV2Example extends StatefulWidget {
  @override
  _VideoCallV2ExampleState createState() => _VideoCallV2ExampleState();
}

class _VideoCallV2ExampleState extends State<TypedVideoCallV2Example> {
  late JanusClient client;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusVideoCallPlugin publishVideo;
  TextEditingController nameController = TextEditingController();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteVideoRenderer = RTCVideoRenderer();
  TextEditingController messageController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey();
  MediaStream? remoteVideoStream;
  AlertDialog? incomingDialog;
  AlertDialog? registerDialog;
  AlertDialog? callDialog;
  List<String> messages = [];
  bool ringing = false;
  bool front = true;
  bool speakerOn = false;
  List<MediaDeviceInfo>? _mediaDevicesList;

  @override
  void initState() {
    super.initState();
    initJanusClient();
    loadDevices();
    navigator.mediaDevices.ondevicechange = (event) async {
      loadDevices();
    };
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await _localRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  _selectAudioInput(String deviceId) async {
    print(deviceId);
    await Helper.selectAudioInput(deviceId);
  }

  Future<void> loadDevices() async {
    if (WebRTC.platformIsAndroid || WebRTC.platformIsIOS) {
      //Ask for runtime permissions if necessary.
      var status = await Permission.bluetooth.request();
      if (status.isPermanentlyDenied) {
        print('BLEpermdisabled');
      }
      status = await Permission.bluetoothConnect.request();
      if (status.isPermanentlyDenied) {
        print('ConnectPermdisabled');
      }
    }
    final devices = await navigator.mediaDevices.enumerateDevices();
    setState(() {
      _mediaDevicesList = devices;
    });
  }

  Future<void> localMediaSetup() async {
    await _localRenderer.initialize();
    await publishVideo.initDataChannel();
    await publishVideo.initializeMediaDevices(mediaConstraints: {'audio': true, 'video': true});
    _localRenderer.srcObject = publishVideo.webRTCHandle?.localStream;
  }

  makeCall() async {
    await localMediaSetup();
    await publishVideo.initDataChannel();
    var offer = await publishVideo.createOffer(
      audioRecv: true,
      videoRecv: true,
    );
    await publishVideo.call(nameController.text, offer: offer);
    nameController.text = "";
  }

  openRegisterDialog() async {
    registerDialog = await showDialog<AlertDialog>(
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
                        return null;
                      },
                      onFieldSubmitted: (v) {
                        registerUser();
                      },
                    ),
                    Padding(padding: EdgeInsets.all(9)),
                    ElevatedButton(
                      onPressed: () async {
                        await registerUser();
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
    callDialog = await showDialog<AlertDialog>(
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
                ElevatedButton(
                  onPressed: () async {
                    await makeCall();
                  },
                  child: Text("Call"),
                )
              ],
            ),
          );
        });
  }

  initJanusClient() async {
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    client = JanusClient(transport: ws, iceServers: [RTCIceServer(urls: "stun:stun.voip.eutelia.it:3478", username: "", credential: "")], isUnifiedPlan: true);
    session = await client.createSession();
    publishVideo = await session.attach<JanusVideoCallPlugin>();
    await _remoteVideoRenderer.initialize();
    MediaStream? tempVideo = await createLocalMediaStream('remoteVideoStream');
    setState(() {
      remoteVideoStream = tempVideo;
    });
    publishVideo.data?.listen((event) async {
      setState(() {
        messages.add(event.text);
      });
    });
    publishVideo.webRTCHandle?.peerConnection?.onConnectionState = (connectionState) async {
      if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        print('connection established');
      }
    };
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
        Navigator.of(context).pop(registerDialog);
        print(data.result?.username);
        nameController.clear();
        await makeCallDialog();
      }
      if (data is VideoCallIncomingCallEvent) {
        incomingDialog = await showIncomingCallDialog(data.result!.username!, even.jsep);
      }
      if (data is VideoCallAcceptedEvent) {
        setState(() {
          ringing = false;
        });
      }
      if (data is VideoCallCallingEvent) {
        Navigator.of(context).pop(callDialog);
        setState(() {
          ringing = true;
        });
      }
      if (data is VideoCallHangupEvent) {
        await destroy();
      }
      await publishVideo.handleRemoteJsep(even.jsep);
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

  Future<void> registerUser() async {
    if (formKey.currentState?.validate() == true) {
      await publishVideo.register(nameController.text);
    }
  }

  destroy() async {
    await stopAllTracksAndDispose(publishVideo.webRTCHandle?.localStream);
    await stopAllTracksAndDispose(remoteVideoStream);
    publishVideo.dispose();
    session.dispose();
    Navigator.of(context).pop();
  }

  Future<dynamic> showIncomingCallDialog(String caller, RTCSessionDescription? jsep) async {
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
                    var answer = await publishVideo.createAnswer();
                    await publishVideo.acceptCall(answer: answer);
                    Navigator.of(context).pop(incomingDialog);
                    Navigator.of(context).pop(callDialog);
                  },
                  child: Text('Accept')),
              ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true).pop(incomingDialog);
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
      appBar: AppBar(actions: [
        PopupMenuButton<String>(
          onSelected: _selectAudioInput,
          icon: Icon(Icons.input),
          itemBuilder: (BuildContext context) {
            if (_mediaDevicesList != null) {
              return _mediaDevicesList!.where((device) => device.kind == 'audioinput').map((device) {
                return PopupMenuItem<String>(
                  value: device.deviceId,
                  child: Text(device.label),
                );
              }).toList();
            }
            return [];
          },
        ),
        Row(
          children: [
            Text('Speaker'),
            CupertinoSwitch(
              // This bool value toggles the switch.
              value: speakerOn,
              thumbColor: CupertinoColors.systemBlue,
              trackColor: CupertinoColors.systemRed.withOpacity(0.14),
              activeColor: CupertinoColors.systemRed.withOpacity(0.64),
              onChanged: (bool? value) async {
                // This is called when the user toggles the switch.
                setState(() {
                  speakerOn = value!;
                });
                await Helper.setSpeakerphoneOn(speakerOn);
              },
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        IconButton(
            icon: Icon(Icons.cameraswitch_outlined),
            color: Colors.white,
            splashRadius: 25,
            onPressed: () async {
              setState(() {
                front = !front;
              });
              //  note:- deviceId is important for web browsers
              await publishVideo.switchCamera(deviceId: await getCameraDeviceId(front));

              // everytime we make changes in stream we update in ui and renderer like this.
              setState(() {
                _localRenderer.srcObject = publishVideo.webRTCHandle?.localStream;
              });
            })
      ]),
      body: Stack(children: [
        Row(children: [
          Flexible(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Stack(
                  children: [
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
          )),
          Flexible(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  flex: 2,
                  child: ListView(
                    children: List.generate(messages.length, (index) => Text('${messages[index]}')),
                  )),
              Flexible(
                  child: Row(
                children: [
                  Flexible(
                      child: TextFormField(
                    controller: messageController,
                    decoration: InputDecoration(label: Text('Data channel message')),
                  )),
                  Flexible(
                      child: TextButton(
                          onPressed: () async {
                            await publishVideo.sendData(messageController.text);
                            setState(() {
                              messages.add(messageController.text);
                            });
                            messageController.clear();
                          },
                          child: Text('send')))
                ],
              ))
            ],
          ))
        ]),
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 60,
            decoration: BoxDecoration(color: ringing ? Colors.green : Colors.grey.withOpacity(0.3)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                    visible: ringing,
                    child: Text(
                      "Ringing...",
                      style: TextStyle(color: Colors.white),
                    )),
              ],
            ),
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
                      destroy();
                      await publishVideo.hangup();
                      // destroy();
                    })),
            padding: EdgeInsets.all(10),
          ),
        )
      ]),
    );
  }

  Future<void> cleanUpWebRTCStuff() async {
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
