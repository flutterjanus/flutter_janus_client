import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Janus Client Menu")),
        body: ListView(
          children: [
            Divider(),
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
              title: Text("Video Call V2"),
              onTap: () {
                Navigator.of(context).pushNamed("/video_call_v2");
              },
            ),
            ListTile(
              title: Text("Streaming V2"),
              onTap: () {
                Navigator.of(context).pushNamed("/streaming_v2");
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
        ));
  }
}
