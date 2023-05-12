import 'package:flutter/material.dart';
import 'package:janus_client_example/Home.dart';
import 'package:janus_client_example/typed_examples/audio_bridge.dart';
import 'package:janus_client_example/typed_examples/google_meet.dart';
import 'package:janus_client_example/typed_examples/sip.dart';
import 'package:janus_client_example/typed_examples/streaming.dart';
import 'package:janus_client_example/typed_examples/video_call.dart';
import 'typed_examples/text_room.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    themeMode: ThemeMode.light,
    debugShowCheckedModeBanner: false,
    routes: {
      "/google-meet": (c) => GoogleMeet(),
      "/typed_sip": (c) => TypedSipExample(),
      "/typed_streaming": (c) => TypedStreamingV2(),
      "/typed_video_call": (c) => TypedVideoCallV2Example(),
      "/typed_audio_bridge": (c) => TypedAudioRoomV2(),
      "/typed_text_room": (c) => TypedTextRoom(),
      "/": (c) => Home()
    },
  ));
}
