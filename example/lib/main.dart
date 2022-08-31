import 'package:flutter/material.dart';
import 'package:janus_client_example/Home.dart';
import 'package:janus_client_example/typed_examples/audio_bridge.dart';
import 'package:janus_client_example/typed_examples/screen_share_videoroom.dart';
import 'package:janus_client_example/typed_examples/sip.dart';
import 'package:janus_client_example/typed_examples/streaming.dart';
import 'package:janus_client_example/typed_examples/video_call.dart';
import 'typed_examples/text_room.dart';
import 'typed_examples/video_room.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    themeMode: ThemeMode.light,
    debugShowCheckedModeBanner: false,
    routes: {
      "/typed_video_room_v2_unified": (c) => TypedVideoRoomV2Unified(),
      "/typed_sip": (c) => TypedSipExample(),
      "/typed_streaming": (c) => TypedStreamingV2(),
      "/typed_video_call": (c) => TypedVideoCallV2Example(),
      "/typed_audio_bridge": (c) => TypedAudioRoomV2(),
      "/typed_text_room": (c) => TypedTextRoom(),
      "/screen_share_typed_video_room_v2_unified": (c) =>
          TypedScreenShareVideoRoomV2Unified(),
      "/": (c) => Home()
    },
  ));
}
