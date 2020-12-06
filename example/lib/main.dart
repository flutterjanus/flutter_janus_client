import 'package:flutter/material.dart';
import 'package:janus_client_example/Home.dart';
import 'package:janus_client_example/VideoRoom.dart';
import 'package:janus_client_example/streaming.dart';
import 'package:janus_client_example/videoCall.dart';
import 'package:janus_client_example/streaming_unified.dart';
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
        "/streaming": (c) => Streaming(),
        "/streaming_unified": (c) => StreamingUnified(),
        "/": (c) => Home()
      },
    );
  }
}
