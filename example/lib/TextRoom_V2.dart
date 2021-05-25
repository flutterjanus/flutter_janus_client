import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

class TextRoomV2Example extends StatefulWidget {
  @override
  _TextRoomExampleState createState() => _TextRoomExampleState();
}

class _TextRoomExampleState extends State<TextRoomV2Example> {
  JanusClient janusClient;
  JanusSession session;
  JanusPlugin textRoom;
  List<dynamic> textMessages = [];
  Map<String, String> userNameDisplayMap = {};
  RestJanusTransport rest;
  WebSocketJanusTransport ws;
  TextEditingController nameController = TextEditingController();

  initializeClient() async {
    rest = RestJanusTransport(url: servermap['onemandev_master_rest']);
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    janusClient = JanusClient(
        withCredentials: true,
        apiSecret: "SecureIt",
        transport: ws,
        iceServers: [
          RTCIceServer(
              url: "stun:stun1.l.google.com:19302",
              username: "",
              credential: "")
        ]);
    session = await janusClient.createSession();
    textRoom = await session.attach(JanusPlugins.TEXT_ROOM);
  }

  leave() async {
    await textRoom.sendData(stringify({"request": "leave"}));
    setState(() {
      userNameDisplayMap = {};
      textMessages = [];
    });
    textRoom.dispose();
    session.dispose();
  }

  setup() async {
    var body = {"request": "setup"};
    await textRoom.send(data: body);
    textRoom.messages.listen((event) async {
      if (event.jsep != null) {
        await textRoom.handleRemoteJsep(event.jsep);
        var body = {"request": "ack"};
        await textRoom.initDataChannel();
        RTCSessionDescription answer = await textRoom.createAnswer(
            audioSend: false,
            videoSend: false,
            videoRecv: false,
            audioRecv: false);
        await textRoom.send(
          data: body,
          jsep: answer,
        );
      }
    });
    textRoom.onData.listen((event) async {
      if (RTCDataChannelState.RTCDataChannelOpen == event) {
        print('data channel open trying register');
        var register = {
          'textroom': "join",
          'transaction': randomString(),
          'room': 1234,
          'username': randomString(),
          'display': "Shivansh"
        };
        await textRoom.sendData(stringify(register));
      }
    });

    textRoom.data.listen((event) {
      print('recieved message from data channel');
      dynamic data = parse(event.text);
      print(data);
      if (data != null) {
        if (data['textroom'] == 'message') {
          setState(() {
            textMessages.add(data);
          });
        }
        if (data['textroom'] == 'leave') {
          setState(() {
            textMessages
                .add({'from': data['username'], 'text': 'Left The Chat!'});
            Future.delayed(Duration(seconds: 1)).then((value) {
              userNameDisplayMap.remove(data['username']);
            });
          });
        }
        if (data['textroom'] == 'join') {
          setState(() {
            userNameDisplayMap.putIfAbsent(
                data['username'], () => data['display']);
            textMessages
                .add({'from': data['username'], 'text': 'Joined The Chat!'});
          });
        }
        if (data['participants'] != null) {
          (data['participants'] as List<dynamic>).forEach((element) {
            setState(() {
              userNameDisplayMap.putIfAbsent(
                  element['username'], () => element['display']);
            });
          });
        }
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await initializeClient();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                icon: Icon(
                  Icons.call,
                  color: Colors.greenAccent,
                ),
                onPressed: () async {
                  await setup();
//                  -_localRenderer.
                }),
            IconButton(
                icon: Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                onPressed: () {
                  leave();
                }),
          ],
          title: const Text('janus_client'),
        ),
        body: Column(
          children: [
            Expanded(
                child: ListView.builder(
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      userNameDisplayMap[textMessages[index]['from']] != null
                          ? userNameDisplayMap[textMessages[index]['from']]
                          : ''),
                  subtitle: Text(textMessages[index]['text'] != null
                      ? textMessages[index]['text']
                      : ''),
                );
              },
              itemCount: textMessages.length,
            )),
            Container(
                padding: EdgeInsets.all(10),
                color: Colors.grey,
                child: Row(
                  children: [
                    Flexible(
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration.collapsed(
                            hintText: "Type Your Message"),
                      ),
                      fit: FlexFit.loose,
                      flex: 20,
                    ),
                    Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: IconButton(
                          onPressed: () async {
                            var message = {
                              'transaction': randomString(),
                              "textroom": "message",
                              "room": 1234,
                              "text": nameController.text,
                            };
                            print(message);

                            await textRoom.sendData(stringify(message));
                            nameController.clear();
                          },
                          icon: Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                          color: Colors.green,
                        ))
                  ],
                ))
          ],
        ));
  }
}
