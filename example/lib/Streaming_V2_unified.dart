import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/Helper.dart';
import 'package:janus_client_example/conf.dart';

class StreamingV2Unified extends StatefulWidget {
  @override
  _StreamingState createState() => _StreamingState();
}

class _StreamingState extends State<StreamingV2Unified> {
  late JanusClient j;
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusPlugin plugin;
  Map<int, JanusPlugin> subscriberHandles = {};

  Map<String, RTCVideoRenderer> _remoteRenderers = {};
  Map<String, RTCVideoRenderer> _audioRenderers = {};
  Map<String, MediaStream> mediaStreams = {};

  List<StreamingItem> streams = [];
  late int selectedStreamId;
  bool _loader = true;
  late StateSetter _setState;

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
      j = JanusClient(transport: ws, isUnifiedPlan: true);
    });
    session = await j.createSession();
    print(session.sessionId);
    plugin = await session.attach(JanusPlugins.STREAMING);
    await this.getStreamListing();
    print('got handleId');
    print(plugin.handleId);

    plugin.remoteTrack?.listen((event) async {
      print('remote track found');
      // if (event != null) {
      if(event.flowing!=null
          &&event.track!=null
          &&event.mid!=null&&
          event.track?.muted!=null){
        if (event.track!.kind == "video" && event.flowing! && !event.track!.muted!) {
          MediaStream temp = await createLocalMediaStream("mediaStream_" + event.mid!);
          setState(() {
            _remoteRenderers[event.mid!] = RTCVideoRenderer();
          });
          await _remoteRenderers[event.mid]?.initialize();
          setState(() {
            mediaStreams["mediaStream_" + event.mid!] = temp;
          });
          mediaStreams["mediaStream_" + event.mid!]?.addTrack(event.track!);
          _remoteRenderers[event.mid]?.srcObject = mediaStreams["mediaStream_" + event.mid!];
        }
        if (event.track!.kind == "audio" && event.flowing!) {
          MediaStream temp = await createLocalMediaStream("mediaStream_" + event.mid!);
          setState(() {
            _audioRenderers[event.mid!] = RTCVideoRenderer();
          });
          await _audioRenderers[event.mid]?.initialize();
          setState(() {
            mediaStreams["mediaStream_" + event.mid!] = temp;
          });
          mediaStreams["mediaStream_" + event.mid!]?.addTrack(event.track!);
          _audioRenderers[event.mid]?.srcObject = mediaStreams["mediaStream_" + event.mid!];
          // await _remoteRenderer.initialize();
        }

      }

      // }
    });
    plugin.messages?.listen((even) async {
      print('got onmsg');
      print(even);
      var pluginData = even.event['plugindata'];
      if (pluginData != null) {
        var data = pluginData['data'];
        if (data != null) {
          var msg = data;
          if (msg['streaming'] != null && msg['result'] != null) {
            if (msg['streaming'] == 'event' && msg['result']['status'] == 'stopping') {
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
                      streams = (data['list'] as List<dynamic>).map((e) => StreamingItem.fromMap(e)).toList();
                    });

                    return AlertDialog(
                      title: Text("Choose Stream To Play"),
                      content: Column(
                        children: [
                          DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: selectedStreamId,
                              items: List.generate(streams.length, (index) => DropdownMenuItem(value: streams[index].id, child: Text(streams[index].description))),
                              onChanged: (v) {
                                if (v != null) {
                                  _setState(() {
                                    selectedStreamId = v;
                                  });
                                }
                              }),
                          RaisedButton(
                            color: Colors.green,
                            textColor: Colors.white,
                            onPressed: () {
                              plugin.send(data: {
                                "request": "watch",
                                "id": selectedStreamId,
                                "media": [],
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
        var stereo = (even.jsep?.sdp?.indexOf("stereo=1") != -1);
        if (stereo && even.jsep?.sdp?.indexOf("stereo=1") == -1) {
          // Make sure that our offer contains stereo too
          even.jsep?.sdp = even.jsep?.sdp?.replaceAll("useinbandfec=1", "useinbandfec=1;stereo=1");
        }
        debugPrint("Handling SDP as well..." + even.jsep.toString());
        await plugin.handleRemoteJsep(even.jsep!);
        RTCSessionDescription answer = await plugin.createAnswer(audioSend: false, videoSend: false, videoRecv: true, audioRecv: true);
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
            ..._audioRenderers.values
                .map((e) => Expanded(
                      child: RTCVideoView(
                        e,
                        mirror: false,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ))
                .toList()
          ],
        ),
        Column(
          children: [
            ..._remoteRenderers.values
                .map((e) => Expanded(
                      child: RTCVideoView(
                        e,
                        mirror: false,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                  children: [CircularProgressIndicator(), Padding(padding: EdgeInsets.all(10)), Text("Fetching Available Streams..")],
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
