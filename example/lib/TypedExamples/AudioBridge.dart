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

class TypedAudioRoomV2 extends StatefulWidget {
  @override
  _AudioRoomState createState() => _AudioRoomState();
}

class _AudioRoomState extends State<TypedAudioRoomV2> {
  late JanusClient j;
  late JanusSession session;
  late JanusAudioBridgePlugin pluginHandle;
  late WebSocketJanusTransport ws;
  late Map<String, MediaStream?> allStreams = {};
  late Map<String, RTCVideoRenderer> remoteRenderers = {};
  List<Participant> participants = [];

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  initRenderers() async {}

  Future<void> initPlatformState() async {
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    j = JanusClient(withCredentials: true, isUnifiedPlan: true, apiSecret: "SecureIt", transport: ws, iceServers: [RTCIceServer(urls: "stun:stun1.l.google.com:19302", username: "", credential: "")]);
    session = await j.createSession();
    pluginHandle = await session.attach<JanusAudioBridgePlugin>();
    // MediaStream? stream = await pluginHandle.initializeMediaDevices(mediaConstraints: {"audio": true, "video": false});
    // setState(() {
    //   allStreams.putIfAbsent("0", () => stream);
    // });
    pluginHandle.joinRoom(1234, display: "Shivansh");
    pluginHandle.remoteTrack?.listen((event) async {
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
        print(remoteRenderers);
      }
    });
    pluginHandle.messages?.listen((msg) async {
      print(msg.event);
      if (msg.event['plugindata'] != null) {
        if (msg.event['plugindata']['data'] != null) {
          var data = msg.event['plugindata']['data'];
          if (data['audiobridge'] == 'joined') {
            RTCSessionDescription offer = await pluginHandle.createOffer(videoRecv: false, audioRecv: true, videoSend: false, audioSend: true);
            var publish = {"request": "configure"};
            await pluginHandle.send(data: publish, jsep: offer);
            data = (await pluginHandle.send(data: {'request': 'listparticipants', 'room': 1234}))['plugindata']['data'];
            var participant = data['participants'];
            if (participant is List && participant != null) {
              setState(() {
                var temp = participant.map((element) {
                  return Participant(
                      id: element['id'], display: element['display'], setup: element['setup'], muted: element['muted'], talking: element['talking'] != null ? element['talking'] : false);
                }).toList();
                temp.forEach((element) {
                  var existingIndex = participants.indexWhere((eleme) => eleme.id == element.id);
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
                      id: element['id'], display: element['display'], setup: element['setup'], muted: element['muted'], talking: element['talking'] != null ? element['talking'] : false);
                }).toList();
                temp.forEach((element) {
                  var existingIndex = participants.indexWhere((eleme) => eleme.id == element.id);
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
                participants.removeWhere((element) => element.id == data['leaving']);
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
    int talkingIndex = participants.indexWhere((element) => element.id == data['id']);
    setState(() {
      participants[talkingIndex].talking = talking;
    });
  }

  leave() async {
    setState(() {
      participants.removeWhere((element) => true);
    });
    await pluginHandle.hangup();
    pluginHandle.dispose();
    // stream?.getTracks().forEach((element) {
    //   element.stop();
    // });
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
        Positioned.fill(
          top: 5,
          child: Opacity(
              opacity: 0,
              child: ListView.builder(
                  itemCount: remoteRenderers.entries.map((e) => e.value).length,
                  itemBuilder: (context,index){
                    var renderer=remoteRenderers.entries.map((e) => e.value).toList()[index];
                  return Container(
                    color: Colors.red,
                      width: 50,
                      height: 50,
                      child: RTCVideoView(
                        renderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      ));
                  }
              )

          ),
        ),
        Container(
            child: GridView.builder(
                itemCount: participants.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10),
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
                          participants[index].talking ? Icons.volume_up_sharp : Icons.volume_mute_sharp,
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
