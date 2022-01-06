import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

class TypedStreamingV2 extends StatefulWidget {
  @override
  _StreamingState createState() => _StreamingState();
}

class _StreamingState extends State<TypedStreamingV2> {
  late JanusClient j;
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusStreamingPlugin plugin;
  Map<int, JanusPlugin> subscriberHandles = {};

  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();

  late List<StreamingMountPoint> streams;
   int? selectedStreamId;
  bool _loader = true;

  late StateSetter _setState;
  bool isPlaying=true;

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await _remoteRenderer.initialize();
  }

  showStreamSelectionDialog() async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setstate) {
            _setState = setstate;
            return AlertDialog(
              title: Text("Choose Stream To Play"),
              content: Column(
                children: [
                  DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: selectedStreamId,
                      items: List.generate(streams.length, (index) => DropdownMenuItem(value: streams[index].id, child: Text(streams[index].description ?? ''))),
                      onChanged: (v) {
                        print(v);
                        if (v != null) {
                          _setState(() {
                            selectedStreamId = v;
                          });
                        }
                      }),
                  ElevatedButton(
                    onPressed: () async {
                      await plugin.watchStream(selectedStreamId!);
                      Navigator.of(context).pop();
                    },
                    child: Text("Play"),
                  )
                ],
              ),
            );
          });
        });
  }

  initJanusClient() async {
    setState(() {
      rest = RestJanusTransport(url: servermap['janus_rest']);
      ws = WebSocketJanusTransport(url: servermap['janus_ws']);
      j = JanusClient(transport: ws, iceServers: [RTCIceServer(url: "stun:stun.voip.eutelia.it:3478", username: "", credential: "")]);
    });
    session = await j.createSession();
    print(session.sessionId);
    plugin = await session.attach<JanusStreamingPlugin>();
    var streamList = await plugin.listStreams();
    setState(() {
      streams = streamList;
    });
    showStreamSelectionDialog();
    plugin.remoteStream?.listen((event) {
      _remoteRenderer.srcObject = event;
    });
    plugin.typedMessages?.listen((event) async{
      Object data=event.event.plugindata?.data;
      if(data is StreamingPluginPreparingEvent){
       await plugin.handleRemoteJsep(event.jsep);
        await plugin.startStream();
       setState(() {
         _loader = false;
       });
      }
      if(data is StreamingPluginStoppingEvent){
        destroy();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    super.deactivate();
    destroy();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initJanusClient();
  }

  destroy() async {
    await plugin.send(
      data: {"request": "stop"},
    );
    _remoteRenderer.srcObject=null;
    await plugin.dispose();
    session.dispose();
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
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
            ),
          ],
        ),
        !_loader
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      child: CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 30,
                          child: IconButton(
                              icon: Icon(Icons.stop),
                              color: Colors.white,
                              onPressed: () {
                                destroy();
                                Navigator.of(context).pop();
                              })),
                      padding: EdgeInsets.all(10),
                    ),
                    Padding(
                      child: CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 30,
                          child: IconButton(
                              icon: Icon(isPlaying?Icons.pause:Icons.play_arrow),
                              color: Colors.white,
                              onPressed: () async{
                                if(isPlaying){
                                  await plugin.pauseStream();
                                  setState(() {
                                    isPlaying=false;
                                  });
                                }
                                else{
                                  setState(() {
                                    isPlaying=true;
                                  });
                                  // await plugin.watchStream(selectedStreamId!);
                                  await plugin.startStream();
                                }
                               })),
                      padding: EdgeInsets.all(10),
                    ),
                  ],
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
    destroy();
    super.dispose();
  }
}
