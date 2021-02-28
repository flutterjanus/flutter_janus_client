import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

class TextRoomExample extends StatefulWidget {
  @override
  _TextRoomExampleState createState() => _TextRoomExampleState();
}

class _TextRoomExampleState extends State<TextRoomExample> {
  JanusClient janusClient = JanusClient(iceServers: [
    RTCIceServer(
        url: "stun:stun.voip.eutelia.it:3478", username: "", credential: "")
  ], server: servers, withCredentials: true, apiSecret: "SecureIt");
  Plugin textRoom;
  TextEditingController nameController = TextEditingController();

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

            await textRoom.send(message: body);
          },
          onData: (d) {
            print('msg from datachannel');
            print(d.text);
          },
          onDataOpen: (d) async {
            print('data state changed');
            if (RTCDataChannelState.RTCDataChannelOpen == d) {
              print(d.toString());
              print('data channel open trying register');
              var register = {
                'textroom': "join",
                'transaction': randomString(),
                'room': 1234,
                'username': randomString(),
                'display': "Shivansh"
              };
              await textRoom.sendData(message: stringify(register));
            }
          },
          onWebRTCState: (state) async {},
          onMessage: (msg, jsep) async {
            if (msg != null) {
              print(msg);
            }

            if (jsep != null) {
              await textRoom.handleRemoteJsep(jsep);
              var body = {"request": "ack"};
              await textRoom.initDataChannel();
              RTCSessionDescription answer = await textRoom.createAnswer(
                  offerOptions: {
                    "offerToReceiveAudio": false,
                    "offerToReceiveVideo": false
                  });
              await textRoom.send(
                  message: body,
                  jsep: answer,
              );
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
