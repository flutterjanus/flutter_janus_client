import 'package:flutter/material.dart';
import 'package:janus_client/Plugin.dart';
import 'package:janus_client/janus_client.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class StreamingUnified extends StatefulWidget {
  @override
  _StreamingUnifiedState createState() => _StreamingUnifiedState();
}

class _StreamingUnifiedState extends State<StreamingUnified> {
  JanusClient janusClient = JanusClient(iceServers: [
    RTCIceServer(
        url: "turn:40.85.216.95:3478",
        username: "onemandev",
        credential: "SecureIt")
  ], server: [
    'wss://janus.conf.meetecho.com/ws',
    'wss://janus.onemandev.tech/janus/websocket',
  ], withCredentials: true, apiSecret: "SecureIt", isUnifiedPlan: true);
  Plugin publishVideo;
  TextEditingController nameController = TextEditingController();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  MediaStream _remoteStream;

  List<dynamic> streams = [];
  int selectedStreamId;
  bool _loader = true;

  StateSetter _setState;

  getStreamListing() {
    var body = {"request": "list"};
    publishVideo.send(
        message: body,
        onSuccess: () {
          print("listing");
        },
        onError: (e) {
          print('got error in listing');
          print(e);
        });
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await _remoteRenderer.initialize();
    _remoteStream = await createLocalMediaStream("local");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    janusClient.connect(onSuccess: (sessionId) {
      janusClient.attach(Plugin(
          onRemoteTrack: (stream, track, mid, on) {
            print('got remote stream');
            _remoteStream
                .addTrack(track)
                .then((value) => _remoteRenderer.srcObject = _remoteStream);
          },
          plugin: "janus.plugin.streaming",
          onMessage: (msg, jsep) async {
            print('got onmsg');
            print(msg);
            if (msg['janus'] == 'success' && msg['plugindata'] != null) {
              var plugindata = msg['plugindata'];
              print('got plugin data');
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  child: StatefulBuilder(builder: (context, setstate) {
                    _setState = setstate;
                    _setState(() {
                      streams = plugindata['data']['list'];
                    });

                    return AlertDialog(
                      title: Text("Choose Stream To Play"),
                      content: Column(
                        children: [
                          DropdownButtonFormField(
                              isExpanded: true,
                              value: selectedStreamId,
                              items: List.generate(
                                  streams.length,
                                  (index) => DropdownMenuItem(
                                      value: streams[index]['id'],
                                      child:
                                          Text(streams[index]['description']))),
                              onChanged: (v) {
                                _setState(() {
                                  selectedStreamId = v;
                                });
                              }),
                          RaisedButton(
                            color: Colors.green,
                            textColor: Colors.white,
                            onPressed: () {
                              publishVideo.send(message: {
                                "request": "watch",
                                "id": selectedStreamId,
                                "offer_audio": true,
                                "offer_video": true,
                              });
                            },
                            child: Text("Play"),
                          )
                        ],
                      ),
                    );
                  }));
            }

            if (jsep != null) {
              debugPrint("Handling SDP as well..." + jsep.toString());
              await publishVideo.handleRemoteJsep(jsep);
              RTCSessionDescription answer = await publishVideo.createAnswer();
              publishVideo.send(message: {"request": "start"}, jsep: answer);
              Navigator.of(context).pop();
              setState(() {
                _loader = false;
              });
            }
          },
          onSuccess: (plugin) {
            setState(() {
              publishVideo = plugin;
              this.getStreamListing();
            });
          }));
    });
  }

  Future<void> cleanUpAndBack() async {
    await publishVideo.destroy();
    janusClient.destroy();
    await _remoteRenderer.dispose();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Column(
          children: [
            Expanded(
              child: RTCVideoView(
                _remoteRenderer,
                mirror: false,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ],
        ),
        !_loader
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 30,
                      child: IconButton(
                          icon: Icon(Icons.stop),
                          color: Colors.white,
                          onPressed: () {
                            publishVideo.send(
                                message: {"request": "stop"},
                                onSuccess: () async {
                                  await cleanUpAndBack();
                                });
                          })),
                  padding: EdgeInsets.all(10),
                ),
              )
            : Padding(padding: EdgeInsets.zero),
        _loader
            ? Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    Padding(padding: EdgeInsets.all(10)),
                    Text("Fetching Available Streams..")
                  ],
                ),
              )
            : Padding(padding: EdgeInsets.zero),
      ]),
    );
  }

  @override
  void dispose() async {
    // TODO: implement dispose
    super.dispose();
  }
}
