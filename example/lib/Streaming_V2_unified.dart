import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

class StreamingV2Unified extends StatefulWidget {
  @override
  _StreamingState createState() => _StreamingState();
}

class _StreamingState extends State<StreamingV2Unified> {
  JanusClient j;
  RestJanusTransport rest;
  WebSocketJanusTransport ws;
  JanusSession session;
  JanusPlugin plugin;
  Map<int, JanusPlugin> subscriberHandles = {};

  Map<String, RTCVideoRenderer> _remoteRenderers = {};

  List<dynamic> streams = [];
  int selectedStreamId;
  bool _loader = true;

  StateSetter _setState;

  getStreamListing() {
    var body = {"request": "list"};
    plugin.send(
      data: body,
    );
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  initJanusClient() async {
    setState(() {
      rest = RestJanusTransport(url: servermap['janus_rest']);
      ws = WebSocketJanusTransport(url: servermap['janus_ws']);
      j = JanusClient(
          transport: ws,
          iceServers: [
            RTCIceServer(
                url: "stun:stun.voip.eutelia.it:3478",
                username: "",
                credential: "")
          ],
          isUnifiedPlan: true);
    });
    session = await j.createSession();
    print(session.sessionId);
    plugin = await session.attach(JanusPlugins.STREAMING);
    await this.getStreamListing();
    print('got handleId');
    print(plugin.handleId);

    plugin.remoteTrack.listen((event) async {
      print('remote track found');
      print(event.toMap());
      // if (event != null) {
      if (event.track.kind == "video") {
        setState(() {
          _remoteRenderers[event.mid] = RTCVideoRenderer();
        });
        await _remoteRenderers[event.mid].initialize();
        MediaStream mediaStream = await createLocalMediaStream(event.mid);
        mediaStream.addTrack(event.track);
        _remoteRenderers[event.mid].srcObject = mediaStream;
        // await _remoteRenderer.initialize();
      }
      if (event.track.kind == "audio") {
        setState(() {
          _remoteRenderers[event.mid] = RTCVideoRenderer();
        });
        await _remoteRenderers[event.mid].initialize();
        MediaStream mediaStream = await createLocalMediaStream(event.mid);
        mediaStream.addTrack(event.track);
        _remoteRenderers[event.mid].srcObject = mediaStream;
        // await _remoteRenderer.initialize();
      }

      // }
    });
    plugin.messages.listen((even) async {
      print('got onmsg');
      print(even);
      var pluginData = even.event['plugindata'];
      if (pluginData != null) {
        var data = pluginData['data'];
        if (data != null) {
          var msg = data;
          if (msg['streaming'] != null && msg['result'] != null) {
            if (msg['streaming'] == 'event' &&
                msg['result']['status'] == 'stopping') {
              await this.destroy();
            }
          }
          if (data['streaming'] == 'list') {
            showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return StatefulBuilder(builder: (context, setstate) {
                    _setState = setstate;
                    _setState(() {
                      streams = data['list'];
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
                              plugin.send(data: {
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
                  });
                });
          }
        }
      }

      if (even.jsep != null) {
        debugPrint("Handling SDP as well..." + even.jsep.toString());
        even.jsep.sdp = even.jsep.sdp
            .replaceAll("useinbandfec=1", "useinbandfec=1;stereo=1");
        await plugin.handleRemoteJsep(even.jsep);
        RTCSessionDescription answer =
            await plugin.createAnswer(audioSend: false, videoSend: false);
        plugin.send(data: {"request": "start"}, jsep: answer);
        Navigator.of(context).pop();
        setState(() {
          _loader = false;
        });
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initJanusClient();
  }

  Future<void> cleanUpAndBack() async {
    plugin.send(data: {"request": "stop"});
  }

  destroy() async {
    await plugin.dispose();
    session.dispose();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Column(
          children: [
            ..._remoteRenderers.values
                .map((e) => Expanded(
                      child: RTCVideoView(
                        e,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ))
                .toList()
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
                            plugin.send(
                              data: {"request": "stop"},
                            );
                            // onSuccess: () async {
                            //   plugin.send(message: {});
                            // }
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
