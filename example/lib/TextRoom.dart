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
        url: "stun:stun.voip.eutelia.it:3478",
        username: "",
        credential: "")
  ], server: servers, withCredentials: true, apiSecret: "SecureIt");
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
          onWebRTCState: (state)async{
            if(state==RTCPeerConnectionState.RTCPeerConnectionStateConnected){
              await textRoom.initDataChannel(label: label);
            }
          },
          onMessage: (msg, jsep) async {
            if (msg != null) {
              print(msg);
            }

            if (jsep != null) {
              textRoom.handleRemoteJsep(jsep);
              var body = {"request": "ack"};
              RTCSessionDescription answer = await textRoom.createAnswer(offerOptions:{"offerToReceiveAudio": false,
                "offerToReceiveVideo": false});
              textRoom.send(
                  message: body, jsep: answer, onSuccess: () async {
                    print('creating data channel');


              });

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
