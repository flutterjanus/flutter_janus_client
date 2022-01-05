import 'dart:html';

import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:janus_client_example/conf.dart';

class Participant {
  num id;
  String display;
  bool setup;
  bool muted;
  bool talking;

//<editor-fold desc="Data Methods">

  Participant({
    required this.id,
    required this.display,
    required this.setup,
    required this.muted,
    required this.talking,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Participant && runtimeType == other.runtimeType && id == other.id && display == other.display && setup == other.setup && muted == other.muted && talking == other.talking);

  @override
  int get hashCode => id.hashCode ^ display.hashCode ^ setup.hashCode ^ muted.hashCode ^ talking.hashCode;

  @override
  String toString() {
    return 'Participant{' + ' id: $id,' + ' display: $display,' + ' setup: $setup,' + ' muted: $muted,' + ' talking: $talking,' + '}';
  }

  Participant copyWith({
    num? id,
    String? display,
    bool? setup,
    bool? muted,
    bool? talking,
  }) {
    return Participant(
      id: id ?? this.id,
      display: display ?? this.display,
      setup: setup ?? this.setup,
      muted: muted ?? this.muted,
      talking: talking ?? this.talking,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'display': this.display,
      'setup': this.setup,
      'muted': this.muted,
      'talking': this.talking,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'] as num,
      display: map['display'] as String,
      setup: map['setup'] as bool,
      muted: map['muted'] as bool,
      talking: map['talking'] as bool,
    );
  }

//</editor-fold>
}

class AudioRoomV2 extends StatefulWidget {
  @override
  _AudioRoomState createState() => _AudioRoomState();
}

class _AudioRoomState extends State<AudioRoomV2> {
  late JanusClient j;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  late JanusSession session;
  late JanusPlugin pluginHandle;
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late MediaStream remoteStream;
  late MediaStream myStream;
  List<Participant> participants = [];
  MediaStream? stream;

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
    rest = RestJanusTransport(url: servermap['janus_rest']);
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    j = JanusClient(
        withCredentials: true,
        apiSecret: "SecureIt",
        transport: ws,
        iceServers: [
          RTCIceServer(
              url: "stun:stun1.l.google.com:19302",
              username: "",
              credential: "")
        ]);
    session = await j.createSession();
    pluginHandle = await session.attach<JanusAudioBridgePlugin>();
    stream=await pluginHandle.initializeMediaDevices(
        mediaConstraints: {"audio": true, "video": false});

    var register = {"request": "join", "room": 1234, "display": 'shivansh'};
    await pluginHandle.send(data: register);
    pluginHandle.remoteStream?.listen((event) {
      _remoteRenderer.srcObject = event;
    });
    pluginHandle.messages?.listen((msg) async {
      print(msg.event);
      if (msg.event['plugindata'] != null) {
        if (msg.event['plugindata']['data'] != null) {
          var data = msg.event['plugindata']['data'];
          if (data['audiobridge'] == 'joined') {
            RTCSessionDescription offer = await pluginHandle.createOffer(
                videoRecv: false,
                audioRecv: true,
                videoSend: false,
                audioSend: false);
            var publish = {"request": "configure"};
            await pluginHandle.send(data: publish, jsep: offer);
            data = (await pluginHandle.send(data: {
              'request': 'listparticipants',
              'room': 1234
            }))['plugindata']['data'];
            var participant = data['participants'];
            if (participant is List && participant != null) {
              setState(() {
                var temp = participant.map((element) {
                  return Participant(
                      id: element['id'],
                      display: element['display'],
                      setup: element['setup'],
                      muted: element['muted'],
                      talking: element['talking']!=null?element['talking']:false);
                }).toList();
                temp.forEach((element) {
                  var existingIndex = participants
                      .indexWhere((eleme) => eleme.id == element.id);
                  if (existingIndex > -1) {
                    participants[existingIndex] = element;
                  } else {
                    participants.add(element);
                  }
                });
              });
            }
          }
          if (data['audiobridge'] == 'talking') {
            updateTalkingId(data, true);
          }
          if (data['audiobridge'] == 'stopped-talking') {
            updateTalkingId(data, false);
          }
          if (data['audiobridge'] == 'event') {
            var participant = data['participants'];
            if (participant is List && participant != null) {
              setState(() {
                var temp = participant.map((element) {
                  return Participant(
                      id: element['id'],
                      display: element['display'],
                      setup: element['setup'],
                      muted: element['muted'],
                      talking: element['talking']!=null?element['talking']:false);
                }).toList();
                temp.forEach((element) {
                  var existingIndex = participants
                      .indexWhere((eleme) => eleme.id == element.id);
                  if (existingIndex > -1) {
                    participants[existingIndex] = element;
                  } else {
                    participants.add(element);
                  }
                });
              });
            }
            if (data['leaving'] != null) {
              setState(() {
                participants
                    .removeWhere((element) => element.id == data['leaving']);
              });
            }
          }
        }
      }
      if (msg.jsep != null) {
        print('got remote jsep');
        await pluginHandle.handleRemoteJsep(msg.jsep!);
      }
    });
  }

  updateTalkingId(data, talking) {
    int talkingIndex =
        participants.indexWhere((element) => element.id == data['id']);
    setState(() {
      participants[talkingIndex].talking = talking;
    });
  }

  leave() async {
    setState(() {
      participants.removeWhere((element) => true);
    });
    await pluginHandle.send(data: {"request": "leave"});
    await pluginHandle.hangup();
    pluginHandle.dispose();
    stream?.getTracks().forEach((element) {
      element.stop();
    });
    session.dispose();
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
                leave();
              }),
        ],
        title: const Text('janus_client'),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Positioned.directional(
          top: 5,
          start: 5,
          textDirection: TextDirection.ltr,
          child: Opacity(
              opacity: 0,
              child: SizedBox(
                  width: 50,
                  height: 50,
                  child: RTCVideoView(
                    _remoteRenderer,
                  ))),
        ),
        Container(
            child: GridView.builder(
                itemCount: participants.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 10),
                itemBuilder: (context, index) {
                  return Container(
                    color: Colors.green,
                    child: Column(
                      children: [
                        Text(participants[index].display),
                        Icon(
                          participants[index].muted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                        Icon(
                          participants[index].talking
                              ? Icons.volume_up_sharp
                              : Icons.volume_mute_sharp,
                          color: Colors.white,
                        )
                      ],
                    ),
                  );
                }))
      ]),
    );
  }
}
