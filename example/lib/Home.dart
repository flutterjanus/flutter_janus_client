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
  Future<void> initState() async {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Janus Client Menu")),
        body: Column(
          children: [
            ListTile(
              title: Text("Video Call Example"),
              onTap: () {
                Navigator.of(context).pushNamed("/video_call");
              },
            ),
            ListTile(
              title: Text("Text Room Example"),
              onTap: () {
                Navigator.of(context).pushNamed("/text_room");
              },
            ),
            ListTile(
              title: Text("Video Room Example"),
              onTap: () {
                Navigator.of(context).pushNamed("/video_room");
              },
            ),
            ListTile(
              title: Text("Audio Room Example"),
              onTap: () {
                Navigator.of(context).pushNamed("/audio_room");
              },
            ),
            ListTile(
              title: Text("Streaming Example"),
              onTap: () {
                Navigator.of(context).pushNamed("/streaming");
              },
            ),
            ListTile(
              title: Text("Streaming Unified Example (MultiStream Support)"),
              onTap: () {
                Navigator.of(context).pushNamed("/streaming_unified");
              },
            ),
            ListTile(
              title: Text("Sip Call Example"),
              onTap: () {
                Navigator.of(context).pushNamed("/sip_call");
              },
            ),
            Divider(),

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
              title: Text("Video Room V2 Unified"),
              onTap: () {
                Navigator.of(context).pushNamed("/video_room_v2_unified");
              },
            ),
          ],
        ));
  }
}
