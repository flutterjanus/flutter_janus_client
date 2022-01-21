import 'package:flutter/material.dart';
import 'package:janus_client_example/AudioRoom_V2.dart';
import 'package:janus_client_example/Home.dart';
import 'package:janus_client_example/Streaming_V2.dart';
import 'package:janus_client_example/Streaming_V2_unified.dart';
import 'package:janus_client_example/TextRoom_V2.dart';
import 'package:janus_client_example/TypedExamples/Streaming.dart';
import 'package:janus_client_example/TypedExamples/VideoCall.dart';
import 'package:janus_client_example/VideoCall_V2.dart';
import 'package:janus_client_example/VideoRoom_V2.dart';
import 'TypedExamples/VideoRoom.dart';
import 'VideoRoom_V2_unified.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    debugShowCheckedModeBanner: false,
    routes: {
      "/video_call_v2": (c) => VideoCallV2Example(),
      "/old_menu": (c) => OldExamplesMenu(),
      "/video_room_v2": (c) => VideoRoomV2(),
      "/video_room_v2_unified": (c) => VideoRoomV2Unified(),
      "/typed_video_room_v2_unified": (c) => TypedVideoRoomV2Unified(),
      "/typed_streaming": (c) => TypedStreamingV2(),
      "/typed_video_call": (c) => TypedVideoCallV2Example(),
      "/audio_room_v2": (c) => AudioRoomV2(),
      "/text_room_v2": (c) => TextRoomV2Example(),
      "/streaming_v2": (c) => StreamingV2(),
      "/streaming_v2_unified": (c) => StreamingV2Unified(),
      "/": (c) => Home()
    },
  ));
}

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   @override
//   Widget build(BuildContext context) {
//     return
//   }
// }
