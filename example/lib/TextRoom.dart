import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class TextRoomExample extends StatefulWidget {
  @override
  _TextRoomExampleState createState() => _TextRoomExampleState();
}

class _TextRoomExampleState extends State<TextRoomExample> {
  JanusClient janusClient = JanusClient(iceServers: [
    RTCIceServer(
        url: "turn:40.85.216.95:3478",
        username: "onemandev",
        credential: "SecureIt")
  ], server: [
    'wss://janus.conf.meetecho.com/ws',
    'https://master-janus.onemandev.tech/rest',
    'wss://janus.onemandev.tech/janus/websocket',
  ], withCredentials: true, apiSecret: "SecureIt");
  Plugin textRoom;
  TextEditingController nameController = TextEditingController();
  String label = "mychatroom";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    janusClient.connect(onSuccess: (sessionId) {
      janusClient.attach(Plugin(
          plugin: "janus.plugin.textroom",
          onSuccess: (plugin) async {
            setState(() {
              textRoom = plugin;
            });
            var body = {"request": "setup"};

            textRoom.send(message: body);
          },
          onData: (d) {
            print('msg from datachannel');
            print(d.text);
          },
          onDataOpen: (d) {
            print('data state changed');
            // if (RTCDataChannelState.RTCDataChannelOpen == d) {
            print(d);
            print('data channel open trying register');
            var register = {
              'textroom': "join",
              'transaction': 'randomsake',
              'room': 1234,
              'username': 123456,
              'display': 'Shivansh'
            };
            textRoom.sendData(label: label, message: stringify(register));
            // }
          },
          onMessage: (msg, jsep) async {
            if (msg != null) {
              print(msg);
            }

            if (jsep != null) {
              textRoom.handleRemoteJsep(jsep);
              var body = {"request": "ack"};
              RTCSessionDescription answer = await textRoom.createAnswer();
              textRoom.send(
                  message: body, jsep: answer, onSuccess: () async {});
              await textRoom.initDataChannel(label: label);
            }
          }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Room example'),
      ),
      body: Column(
        children: [],
      ),
    );
  }
}
