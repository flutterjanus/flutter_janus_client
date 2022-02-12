import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

class TypedTextRoom extends StatefulWidget {
  @override
  _TextRoomExampleState createState() => _TextRoomExampleState();
}

class _TextRoomExampleState extends State<TypedTextRoom> {
  late JanusClient janusClient;
  late JanusSession session;
  late JanusTextRoomPlugin textRoom;
  List<dynamic> textMessages = [];
  Map<String, String> userNameDisplayMap = {};
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  TextEditingController nameController = TextEditingController();
  ScrollController controller = ScrollController();
  FocusNode focusNode=FocusNode();

  initializeClient() async {
    rest = RestJanusTransport(url: servermap['janus_rest']);
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    janusClient = JanusClient(
        withCredentials: true,
        apiSecret: "SecureIt",
        transport: ws,
        iceServers: [
          RTCIceServer(
              urls: "stun:stun1.l.google.com:19302",
              username: "",
              credential: "")
        ]);
    session = await janusClient.createSession();
    textRoom = await session.attach<JanusTextRoomPlugin>();
  }

  leave() async {
    try {
      await textRoom.leaveRoom(1234);
      setState(() {
        userNameDisplayMap = {};
        textMessages = [];
      });
      textRoom.dispose();
      session.dispose();
    } catch (e) {
      print('no connection skipping');
    }
  }

  setup() async {
    await textRoom.setup();
    textRoom.onData?.listen((event) async {
      if (RTCDataChannelState.RTCDataChannelOpen == event) {
        await textRoom.joinRoom(1234, "shivansh", display: "shivansh");
      }
    });

    textRoom.data?.listen((event) {
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
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    this.textRoom.dispose();
    this.session.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeClient();
  }

  Future<void> sendMessage() async {
    await textRoom.sendMessage(1234, nameController.text);
    controller.jumpTo(controller.position.maxScrollExtent);
    nameController.text='';

  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
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
              controller: controller,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      userNameDisplayMap[textMessages[index]['from']] != null
                          ? userNameDisplayMap[textMessages[index]['from']]!
                          : ''),
                  subtitle: Text(textMessages[index]['text'] != null
                      ? textMessages[index]['text']
                      : ''),
                );
              },
              itemCount: textMessages.length,
            )),
            Container(
              height: 60,
                padding: EdgeInsets.only(left: 20,right: 20,top: 5,),
                color: Colors.grey.shade300,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: TextFormField(
                        onFieldSubmitted: (b)async{
                          await sendMessage();
                        },
                        controller: nameController,
                        cursorHeight: 24,
                        decoration: InputDecoration.collapsed(
                            hintText: "Type Your Message"),
                        focusNode: focusNode,
                      ),
                      fit: FlexFit.loose,
                      flex: 20,
                    ),
                    Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: IconButton(
                          onPressed: () async {
                            await sendMessage();
                          },
                          icon: Icon(
                            Icons.send,
                            color: Colors.green,
                          ),
                          color: Colors.white,
                        ))
                  ],
                ))
          ],
        ));
  }
}
