import 'package:flutter/material.dart';
import './Home.dart';
import './typed_examples/audio_bridge.dart';
import './typed_examples/google_meet.dart';
import './typed_examples/sip.dart';
import './typed_examples/streaming.dart';
import './typed_examples/video_call.dart';
import 'typed_examples/text_room.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    theme: ThemeData(
        colorScheme: ColorScheme.light(surface: Colors.white, primary: Colors.black, secondary: Colors.black, onPrimary: Colors.white, onSecondary: Colors.white),
        listTileTheme: ListTileThemeData(titleTextStyle: TextStyle(color: Colors.black)),
        appBarTheme: AppBarTheme(titleTextStyle: TextStyle(color: Colors.white), backgroundColor: Colors.purple)),
    darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(surface: Colors.black, primary: Colors.white, secondary: Colors.white, onPrimary: Colors.black, onSecondary: Colors.black),
        listTileTheme: ListTileThemeData(titleTextStyle: TextStyle(color: Colors.white)),
        appBarTheme: AppBarTheme(titleTextStyle: TextStyle(color: Colors.white), backgroundColor: Colors.grey)),
    themeMode: ThemeMode.system,
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
