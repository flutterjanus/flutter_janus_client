import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/Plugin.dart';

import 'dart:async';

import 'package:janus_client_example/conf.dart';

class Participant {
  num id;
  String display;
  bool setup;
  bool muted;
  bool talking;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  Participant({
    @required this.id,
    @required this.display,
    @required this.setup,
    @required this.muted,
    @required this.talking,
  });

  Participant copyWith({
    num id,
    String display,
    bool setup,
    bool muted,
    bool talking,
  }) {
    return new Participant(
      id: id ?? this.id,
      display: display ?? this.display,
      setup: setup ?? this.setup,
      muted: muted ?? this.muted,
      talking: talking ?? this.talking,
    );
  }

  @override
  String toString() {
    return 'Participant{id: $id, display: $display, setup: $setup, muted: $muted, talking: $talking}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Participant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          display == other.display &&
          setup == other.setup &&
          muted == other.muted &&
          talking == other.talking);

  @override
  int get hashCode =>
      id.hashCode ^
      display.hashCode ^
      setup.hashCode ^
      muted.hashCode ^
      talking.hashCode;

  factory Participant.fromMap(Map<String, dynamic> map) {
    return new Participant(
      id: map['id'] as num,
      display: map['display'] as String,
      setup: map['setup'] as bool,
      muted: map['muted'] as bool,
      talking: map['talking'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'id': this.id,
      'display': this.display,
      'setup': this.setup,
      'muted': this.muted,
      'talking': this.talking,
    } as Map<String, dynamic>;
  }

//</editor-fold>

}

class AudioRoom extends StatefulWidget {
  @override
  _AudioRoomState createState() => _AudioRoomState();
}

class _AudioRoomState extends State<AudioRoom> {
  JanusClient j;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  Plugin pluginHandle;
  Plugin subscriberHandle;
  MediaStream remoteStream;
  MediaStream myStream;
  List<Participant> participants = [];

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
    setState(() {
      j = JanusClient(iceServers: [
        RTCIceServer(
            url: "stun:40.85.216.95:3478",
            username: "onemandev",
            credential: "SecureIt"),
      ], server: servers, withCredentials: true, apiSecret: "SecureIt");
      j.connect(onSuccess: (sessionId) async {
        debugPrint('voilla! connection established with session id as' +
            sessionId.toString());
        j.attach(Plugin(
            plugin: 'janus.plugin.audiobridge',
            onMessage: (msg, jsep) async {
              var event = msg["audiobridge"];
              print('voilaa event');
              print(event);
              if (event != null && event == 'joined' || event == 'event') {
                var participant = msg['participants'];
                var data = msg['data'];

                if (data != null) {
                  if (data['leaving'] != null) {
                    setState(() {
                      participants.removeWhere(
                          (element) => element.id == data['leaving']);
                    });
                  }
                } else {
                  if (participant is List && participant != null) {
                    setState(() {
                      participants = participant.map((element) {
                        return Participant(
                            id: element['id'],
                            display: element['display'],
                            setup: element['setup'],
                            muted: element['muted'],
                            talking: element['talking']);
                      }).toList();
                    });
                  }
                }
                if (event == 'joined') {
                  RTCSessionDescription offer = await pluginHandle.createOffer(
                      offerToReceiveVideo: false,offerToReceiveAudio: true);
                  var publish = {"request": "configure", "muted": false};
                  pluginHandle.send(message: publish, jsep: offer);
                }
              }

              if (jsep != null) {
                debugPrint('handling jsep');
                pluginHandle.handleRemoteJsep(jsep);
              }
            },
            onRemoteStream: (stream) {
              _remoteRenderer.srcObject = stream;
              remoteStream = stream;
            },
            onSuccess: (plugin) async {
              setState(() {
                pluginHandle = plugin;
              });
              MediaStream stream = await plugin.initializeMediaDevices(
                  mediaConstraints: {"audio": true, "video": false});
              setState(() {
                myStream = stream;
              });
              setState(() {
                _localRenderer.srcObject = myStream;
              });
              var register = {
                "request": "join",
                "room": 1234,
                "display": 'shidddevanscdchfvvf'
              };
              plugin.send(message: register);
            }));
      }, onError: (e) {
        debugPrint('some error occured');
        print(e);
      });
    });
  }

  leave() {
    pluginHandle.send(message: {"request": "leave"});
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
                pluginHandle.hangup();
              }),
        ],
        title: const Text('janus_client'),
      ),
      body: Stack(children: [
        Positioned.directional(
          top: 5,
          start: 5,
          textDirection: TextDirection.ltr,
          child: RTCVideoView(
            _remoteRenderer,
          ),
        ),
        Container(
          child: participants.length > 0
              ? GridView.count(
                  crossAxisCount: participants.length,
                  children: List.generate(
                      participants.length,
                      (index) => Container(
                            color: Colors.red,
                            child: Column(
                              children: [Text(participants[index].display)],
                            ),
                          )),
                )
              : Text('Join Room or No participants yet!'),
        )

        // Align(
        //   child: Container(
        //     child: RTCVideoView(
        //       _localRenderer,
        //     ),
        //     height: 200,
        //     width: 200,
        //   ),
        //   alignment: Alignment.bottomRight,
        // )
      ]),
    );
  }
}
