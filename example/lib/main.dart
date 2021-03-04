import 'package:flutter/material.dart';
import 'package:janus_client_example/Home.dart';
import 'package:janus_client_example/TextRoom.dart';
import 'package:janus_client_example/VideoRoom.dart';
import 'package:janus_client_example/VideoRoom_V2.dart';
import 'package:janus_client_example/streaming.dart';
import 'package:janus_client_example/videoCall.dart';
import 'package:janus_client_example/streaming_unified.dart';
import 'package:janus_client_example/audioRoom.dart';
import 'package:janus_client_example/sipCall.dart';

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
        "/video_room": (c) => VideoRoom(),
        "/video_room_v2": (c) => VideoRoomV2(),
        "/streaming": (c) => Streaming(),
        "/audio_room": (c) => AudioRoom(),
        "/streaming_unified": (c) => StreamingUnified(),
        "/sip_call": (c) => SipCall(),
        "/text_room": (c) => TextRoomExample(),
        "/": (c) => Home()
      },
    );
  }
}
