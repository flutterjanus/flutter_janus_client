import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:janus_client_example/conf.dart';

class TypedAudioRoomV2 extends StatefulWidget {
  @override
  _AudioRoomState createState() => _AudioRoomState();
}

class _AudioRoomState extends State<TypedAudioRoomV2> {
  JanusClient? client;
  JanusSession? session;
  JanusAudioBridgePlugin? pluginHandle;
  late WebSocketJanusTransport ws;
  late Map<String, MediaStream?> allStreams = {};
  late Map<String, RTCVideoRenderer> remoteRenderers = {};
  Map<String?, AudioBridgeParticipants?> participants = {};
  bool muted = false;
  bool callStarted = false;
  int myRoom = 1234;
  List<MediaDeviceInfo>? _mediaDevicesList;
  bool speakerOn = false;

  @override
  void initState() {
    super.initState();
    _refreshMediaDevices();
    navigator.mediaDevices.ondevicechange = (event) async {
      print('++++++ ondevicechange ++++++');
      _refreshMediaDevices();
    };
  }

  Future<void> _refreshMediaDevices() async {
    var devices = await navigator.mediaDevices.enumerateDevices();
    setState(() {
      _mediaDevicesList = devices;
    });
  }

  Future<void> initPlatformState() async {
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    client = JanusClient(
        withCredentials: true,
        isUnifiedPlan: true,
        stringIds: false,
        apiSecret: "SecureIt",
        transport: ws,
        iceServers: [RTCIceServer(urls: "stun:stun1.l.google.com:19302", username: "", credential: "")]);
    session = await client?.createSession();
    pluginHandle = await session?.attach<JanusAudioBridgePlugin>();
    // List<MediaDeviceInfo> devices =
    //     await navigator.mediaDevices.enumerateDevices();
    // MediaDeviceInfo microphone =
    //     devices.firstWhere((element) => element.kind == "audioinput");
    await pluginHandle?.initializeMediaDevices(mediaConstraints: {"audio": true, "video": false});
    pluginHandle?.joinRoom(myRoom, display: "Shivansh");

    // await Helper.selectAudioInput(microphone.deviceId);

    pluginHandle?.remoteTrack?.listen((event) async {
      if (event.track != null && event.flowing == true && event.mid != null) {
        setState(() {
          remoteRenderers.putIfAbsent(event.mid!, () => RTCVideoRenderer());
        });
        await remoteRenderers[event.mid!]?.initialize();
        MediaStream stream = await createLocalMediaStream(event.mid!);
        setState(() {
          allStreams.putIfAbsent(event.mid!, () => stream);
        });
        allStreams[event.mid!]?.addTrack(event.track!);
        remoteRenderers[event.mid!]?.srcObject = allStreams[event.mid!];
        if (kIsWeb) {
          remoteRenderers[event.mid!]?.muted = false;
        }
      }
    });

    pluginHandle?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is AudioBridgeJoinedEvent) {
        await pluginHandle?.configure();
        (await pluginHandle?.listParticipants(myRoom));
        data.participants?.forEach((value) {
          setState(() {
            participants.putIfAbsent(value.id.toString(), () => value);
            if (participants[value.id.toString()] != null) {
              participants[value.id.toString()] = value;
            }
          });
        });
      }
      if (data is AudioBridgeNewParticipantsEvent) {
        data.participants?.forEach((value) {
          setState(() {
            participants.putIfAbsent(value.id.toString(), () => value);
            if (participants[value.id.toString()] != null) {
              participants[value.id.toString()] = value;
            }
          });
        });
      }
      if (data is AudioBridgeTalkingEvent) {
        setState(() {
          participants.update(data.userId.toString(), (value) {
            return value?.copyWith(talking: data.isTalking);
          }, ifAbsent: () {
            return participants[data.userId.toString()]?.copyWith(talking: data.isTalking);
          });
        });
      }
      if (data is AudioBridgeConfiguredEvent) {}
      if (data is AudioBridgeDestroyedEvent) {}
      if (data is AudioBridgeLeavingEvent) {
        setState(() {
          participants.remove(data.leaving.toString());
        });
      }
      await pluginHandle?.handleRemoteJsep(event.jsep);
    });
  }

  leave() async {
    setState(() {
      participants.clear();
    });
    await pluginHandle?.hangup();
    pluginHandle?.dispose();
    session?.dispose();
  }

  cleanUpWebRTCStuff() {
    remoteRenderers.forEach((key, value) async {
      value.srcObject = null;
      await value.dispose();
    });
  }

  void _selectAudioInput(String deviceId) async {
    print(deviceId);
    await Helper.selectAudioInput(deviceId);
  }

  @override
  void dispose() {
    super.dispose();
    cleanUpWebRTCStuff();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
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
              icon: Icon(
                Icons.call,
                color: Colors.greenAccent,
              ),
              onPressed: !callStarted
                  ? () async {
                      setState(() {
                        callStarted = !callStarted;
                      });
                      await this.initPlatformState();
                    }
                  : null),
          IconButton(
              icon: Icon(
                muted ? Icons.mic_off : Icons.mic_outlined,
                color: Colors.white,
              ),
              onPressed: callStarted
                  ? () async {
                      if (pluginHandle?.webRTCHandle?.peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateClosed) {
                        setState(() {
                          muted = !muted;
                        });
                        await pluginHandle?.configure(muted: muted);
                      }
                    }
                  : null),
          IconButton(
              icon: Icon(
                Icons.call_end,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  callStarted = !callStarted;
                });
                leave();
              }),
        ],
        title: const Text('janus_client'),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Positioned.fill(
          top: 5,
          child: Opacity(
              opacity: 0,
              child: ListView.builder(
                  itemCount: remoteRenderers.entries.map((e) => e.value).length,
                  itemBuilder: (context, index) {
                    var renderer = remoteRenderers.entries.map((e) => e.value).toList()[index];
                    return Container(
                        color: Colors.red,
                        width: 50,
                        height: 50,
                        child: RTCVideoView(
                          renderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                        ));
                  })),
        ),
        Container(
            child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          childAspectRatio: 2,
          children: participants.entries
              .map((e) => e.value)
              .map((e) => Container(
                    color: Colors.green,
                    child: Column(
                      children: [
                        Text(e?.display ?? ''),
                        Icon(
                          e?.muted == true ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                        Icon(
                          e?.talking == true ? Icons.volume_up_sharp : Icons.volume_mute_sharp,
                          color: Colors.white,
                        )
                      ],
                    ),
                  ))
              .toList(),
        ))
      ]),
    );
  }
}
