import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:janus_client/JanusSession.dart';
import 'package:janus_client/JanusTransport.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void didChangeDependencies() async{
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    RestJanusTransport rest =
    RestJanusTransport(url: 'https://master-janus.onemandev.tech/res');
    WebSocketJanusTransport ws = WebSocketJanusTransport(
        url: 'wss://master-janus.onemandev.tech/websocket');
    JanusClient j=JanusClient(transport:rest);
    JanusSession session=await j.createSession();
    print(session.sessionId);
    session.attach(JanusPlugins.VIDEO_ROOM);

  }
  @override
  Future<void> initState() {
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
            )
          ],
        ));
  }
}

