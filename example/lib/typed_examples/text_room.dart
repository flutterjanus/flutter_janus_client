import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

class TypedTextRoom extends StatefulWidget {
  @override
  _TextRoomExampleState createState() => _TextRoomExampleState();
}

class _TextRoomExampleState extends State<TypedTextRoom> {
  late JanusClient client;
  late JanusSession session;
  late JanusTextRoomPlugin textRoom;
  List<dynamic> textMessages = [];
  Map<String, String> userNameDisplayMap = {};
  late RestJanusTransport rest;
  int myRoom = 1234;
  late WebSocketJanusTransport ws;
  TextEditingController nameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  ScrollController controller = ScrollController();
  FocusNode focusNode = FocusNode();

  initializeClient() async {
    rest = RestJanusTransport(url: servermap['janus_rest']);
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    client =
        JanusClient(withCredentials: true, apiSecret: "SecureIt", transport: ws, iceServers: [RTCIceServer(urls: "stun:stun1.l.google.com:19302", username: "", credential: "")]);
    session = await client.createSession();
    textRoom = await session.attach<JanusTextRoomPlugin>();
  }

  leave() async {
    try {
      await textRoom.leaveRoom(myRoom);
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
        var dialog;
        dialog = await showDialog(
            barrierDismissible: false,
            useSafeArea: true,
            context: context,
            builder: (context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                child: AlertDialog(
                  insetPadding: EdgeInsets.zero,
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () async {
                            await textRoom.joinRoom(myRoom, userNameController.text, display: userNameController.text);
                            Navigator.of(context).pop(dialog);
                          },
                          child: Text('Join')),
                    )
                  ],
                  title: Text('Register yourself'),
                  content: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            decoration: InputDecoration.collapsed(hintText: "Username"),
                            controller: userNameController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
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
          scrollToBottom();
        }
        if (data['textroom'] == 'leave') {
          setState(() {
            textMessages.add({'from': data['username'], 'text': 'Left The Chat!'});
            Future.delayed(Duration(seconds: 1)).then((value) {
              userNameDisplayMap.remove(data['username']);
            });
          });
          scrollToBottom();
        }
        if (data['textroom'] == 'join') {
          setState(() {
            userNameDisplayMap.putIfAbsent(data['username'], () => data['display']);
            textMessages.add({'from': data['username'], 'text': 'Joined The Chat!'});
          });
          scrollToBottom();
        }
        if (data['participants'] != null) {
          (data['participants'] as List<dynamic>).forEach((element) {
            setState(() {
              userNameDisplayMap.putIfAbsent(element['username'], () => element['display']);
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

  scrollToBottom() {
    controller.animateTo(
      controller.position.maxScrollExtent + 200,
      duration: Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> sendMessage() async {
    await textRoom.sendMessage(myRoom, nameController.text);
    nameController.text = '';
    scrollToBottom();
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
                  title: Text(userNameDisplayMap[textMessages[index]['from']] != null ? userNameDisplayMap[textMessages[index]['from']]! : ''),
                  subtitle: Text(textMessages[index]['text'] != null ? textMessages[index]['text'] : ''),
                );
              },
              itemCount: textMessages.length,
            )),
            Material(
              clipBehavior: Clip.none,
              elevation: 10,
              child: Container(
                  // height: 70,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 5,
                    top: 5,
                  ),
                  // color: Colors.grey.shade300,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Flexible(
                        child: TextFormField(
                          textInputAction: TextInputAction.send,
                          onFieldSubmitted: (b) async {
                            await sendMessage();
                          },
                          controller: nameController,
                          cursorHeight: 24,
                          decoration: InputDecoration.collapsed(hintText: "Type Your Message"),
                          focusNode: focusNode,
                        ),
                        fit: FlexFit.tight,
                        flex: 20,
                      ),
                      Flexible(
                          flex: 1,
                          fit: FlexFit.loose,
                          child: IconButton(
                            iconSize: 20,
                            splashRadius: 24,
                            onPressed: () async {
                              await sendMessage();
                            },
                            icon: Icon(
                              Icons.send,
                              size: 20,
                              color: Colors.green,
                            ),
                            color: Colors.white,
                          ))
                    ],
                  )),
            )
          ],
        ));
  }
}
