import 'package:flutter/material.dart';
import 'package:janus_client/Plugin.dart';
import 'package:janus_client/janus_client.dart';
import 'package:janus_client/utils.dart';

class VideoCallExample extends StatefulWidget {
  @override
  _VideoCallExampleState createState() => _VideoCallExampleState();
}

class _VideoCallExampleState extends State<VideoCallExample> {
  JanusClient janusClient = JanusClient(iceServers: [
    RTCIceServer(
        url: "stun:40.85.216.95:3478",
        username: "onemandev",
        credential: "SecureIt"),
    RTCIceServer(
        url: "turn:40.85.216.95:3478",
        username: "onemandev",
        credential: "SecureIt")
  ], server: [
    'https://janus.onemandev.tech/janus',
  ], withCredentials: true, apiSecret: "SecureIt");
  Plugin publishVideo;
  Plugin subscribeVideo;
  TextEditingController nameController = TextEditingController();

  makeCall() {}

  registerDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        child: AlertDialog(
          title: Text("Register As"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Your Name"),
                controller: nameController,
              ),
              RaisedButton(
                color: Colors.green,
                textColor: Colors.white,
                onPressed: () {
                  registerUser(nameController.text);
                },
                child: Text("Proceed"),
              )
            ],
          ),
        ));
  }

  makeCallDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        child: AlertDialog(
          title: Text("Call Registered User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration:
                    InputDecoration(labelText: "Name Of Registered User"),
                controller: nameController,
              ),
              RaisedButton(
                color: Colors.green,
                textColor: Colors.white,
                onPressed: () {
                  makeCall();
                },
                child: Text("Call"),
              )
            ],
          ),
        ));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    janusClient.connect(onSuccess: (sessionId) {
      janusClient.attach(Plugin(
          plugin: "janus.plugin.videocall",
          onSuccess: (plugin) {
            setState(() {
              publishVideo = plugin;
              registerDialog();
            });
          }));
    });
  }

  registerUser(userName) {
    if (publishVideo != null) {
      publishVideo.send(
          message: {"request": "register", "username": userName},
          onSuccess: (data) {
            print("User registered");
            nameController.text = "";
            print(data);
            Navigator.pop(context);
          },
          onError: (error) {
            print(error);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(icon: Icon(Icons.call), onPressed: makeCallDialog)
        ],
        title: Text("Video Call"),
      ),
      body: Column(
        children: [],
      ),
    );
  }
}
