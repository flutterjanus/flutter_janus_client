import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Janus Client Menu")),
        body: SafeArea(
          child: SingleChildScrollView(
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text.rich(
                      TextSpan(children: [TextSpan(text: "Google meet"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed("/google-meet");
                    },
                  ),
                  ListTile(
                    title: Text.rich(
                      TextSpan(children: [TextSpan(text: "Typed streaming Unified"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed("/typed_streaming");
                    },
                  ),
                  ListTile(
                    title: Text.rich(
                      TextSpan(children: [TextSpan(text: "Typed Video Call Unified"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed("/typed_video_call");
                    },
                  ),
                  ListTile(
                    title: Text.rich(
                      TextSpan(children: [TextSpan(text: "Typed Audio Bridge Unified"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed("/typed_audio_bridge");
                    },
                  ),
                  ListTile(
                    title: Text.rich(
                      TextSpan(children: [TextSpan(text: "Typed Text Room"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed("/typed_text_room");
                    },
                  ),
                  ListTile(
                    title: Text.rich(
                      TextSpan(children: [TextSpan(text: "Typed Sip Example"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed("/typed_sip");
                    },
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
