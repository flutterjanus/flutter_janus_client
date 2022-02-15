import 'package:flutter/material.dart';
import 'package:janus_client_example/audio_room_v2.dart';
import 'package:janus_client_example/Home.dart';
import 'package:janus_client_example/streaming_v2.dart';
import 'package:janus_client_example/streaming_v2_unified.dart';
import 'package:janus_client_example/text_room_v2.dart';
import 'package:janus_client_example/typed_examples/audio_bridge.dart';
import 'package:janus_client_example/typed_examples/streaming.dart';
import 'package:janus_client_example/typed_examples/video_call.dart';
import 'package:janus_client_example/video_call_v2.dart';
import 'package:janus_client_example/video_room_v2.dart';
import 'typed_examples/text_room.dart';
import 'typed_examples/video_room.dart';
import 'video_room_v2_unified.dart';

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
      "/typed_audio_bridge": (c) => TypedAudioRoomV2(),
      "/typed_text_room": (c) => TypedTextRoom(),
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
