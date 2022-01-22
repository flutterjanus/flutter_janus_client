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
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Old V2 Examples'),
                onTap: () {
                  Navigator.of(context).pushNamed("/old_menu");
                },
              ),
              ListTile(
                title: RichText(
                  text: TextSpan(children: [TextSpan(text: "Typed Video Room V2 Unified"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed("/typed_video_room_v2_unified");
                },
              ),
              ListTile(
                title: RichText(
                  text: TextSpan(children: [TextSpan(text: "Typed Streaming Unified"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed("/typed_streaming");
                },
              ),
              ListTile(
                title: RichText(
                  text: TextSpan(children: [TextSpan(text: "Typed Video Call Unified"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed("/typed_video_call");
                },
              ),
              ListTile(
                title: RichText(
                  text: TextSpan(children: [TextSpan(text: "Typed Audio Bridge Unified"), TextSpan(text: "  New", style: TextStyle(color: Colors.green))]),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed("/typed_audio_bridge");
                },
              ),
            ],
          ),
        ));
  }
}

class OldExamplesMenu extends StatelessWidget {
  const OldExamplesMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Janus Client Menu")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text("Text Room V2"),
              onTap: () {
                Navigator.of(context).pushNamed("/text_room_v2");
              },
            ),
            ListTile(
              title: Text("Audio Room V2"),
              onTap: () {
                Navigator.of(context).pushNamed("/audio_room_v2");
              },
            ),
            ListTile(
              title: Text("Video Room V2"),
              onTap: () {
                Navigator.of(context).pushNamed("/video_room_v2");
              },
            ),
            ListTile(
              title: Text("Streaming V2"),
              onTap: () {
                Navigator.of(context).pushNamed("/streaming_v2");
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Title(color: Colors.green, child: Text('Updated Unified Plan Examples')),
            ),
            Divider(),
            ListTile(
              title: Text("Video Call V2 Unified"),
              onTap: () {
                Navigator.of(context).pushNamed("/video_call_v2");
              },
            ),
            ListTile(
              title: Text("Video Room V2 Unified"),
              onTap: () {
                Navigator.of(context).pushNamed("/video_room_v2_unified");
              },
            ),
            ListTile(
              title: Text("Streaming V2 Unified"),
              onTap: () {
                Navigator.of(context).pushNamed("/streaming_v2_unified");
              },
            ),
          ],
        ),
      ),
    );
  }
}
