import 'package:flutter/material.dart';
import 'package:janus_client_example/AudioRoom_V2.dart';
import 'package:janus_client_example/Home.dart';
import 'package:janus_client_example/Streaming_V2.dart';
import 'package:janus_client_example/TextRoom.dart';
import 'package:janus_client_example/TextRoom_V2.dart';
import 'package:janus_client_example/VideoCall_V2.dart';
import 'package:janus_client_example/VideoRoom.dart';
import 'package:janus_client_example/VideoRoom_V2.dart';
import 'package:janus_client_example/streaming.dart';
import 'package:janus_client_example/videoCall.dart';
import 'package:janus_client_example/streaming_unified.dart';
import 'package:janus_client_example/audioRoom.dart';
import 'package:janus_client_example/sipCall.dart';

import 'VideoRoom_V2_unified.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "/video_call": (c) => VideoCallExample(),
        "/video_call_v2": (c) => VideoCallV2Example(),
        "/video_room": (c) => VideoRoom(),
        "/video_room_v2": (c) => VideoRoomV2(),
        "/video_room_v2_unified": (c) => VideoRoomV2Unified(),
        "/audio_room_v2": (c) => AudioRoomV2(),
        "/text_room_v2": (c) => TextRoomV2Example(),
        "/streaming": (c) => Streaming(),
        "/streaming_v2": (c) => StreamingV2(),
        "/audio_room": (c) => AudioRoom(),
        "/streaming_unified": (c) => StreamingUnified(),
        "/sip_call": (c) => SipCall(),
        "/text_room": (c) => TextRoomExample(),
        "/": (c) => Home()
      },
    );
  }
}
