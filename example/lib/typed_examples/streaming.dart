import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client_example/conf.dart';

class TypedStreamingV2 extends StatefulWidget {
  @override
  _StreamingState createState() => _StreamingState();
}

class _StreamingState extends State<TypedStreamingV2> {
  late JanusClient client;
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusStreamingPlugin plugin;
  Map<String, RTCVideoRenderer> remoteVideoRenderers = {};
  Map<String, MediaStream> remoteVideoStreams = {};
  Map<String, MediaStream> remoteAudioStreams = {};
  Map<String, RTCVideoRenderer> remoteAudioRenderers = {};
  late List<StreamingMountPoint> streams;
  int? selectedStreamId;
  bool _loader = true;
  late StateSetter _setState;
  bool isPlaying = true;
  bool isMuted = false;

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
                      onChanged: (v) async {
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
      client = JanusClient(
        transport: ws,
        iceServers: [
          RTCIceServer(username: '', credential: '', urls: 'stun:stun.l.google.com:19302'),
        ],
        isUnifiedPlan: true,
      );
    });
    session = await client.createSession();
    plugin = await session.attach<JanusStreamingPlugin>();
    var streamList = await plugin.listStreams();
    setState(() {
      streams = streamList;
    });
    showStreamSelectionDialog();
    plugin.remoteTrack?.listen((event) async {
      if (event.track != null && event.flowing == true && event.track?.kind == 'audio') {
        MediaStream temp = await createLocalMediaStream(event.track!.id!);
        setState(() {
          remoteAudioRenderers.putIfAbsent(event.track!.id!, () => RTCVideoRenderer());
          remoteAudioStreams.putIfAbsent(event.track!.id!, () => temp);
        });
        await remoteAudioRenderers[event.track!.id!]?.initialize();
        await remoteAudioStreams[event.track!.id!]?.addTrack(event.track!);
        remoteAudioRenderers[event.track!.id!]?.srcObject = remoteAudioStreams[event.track!.id!];
        if (kIsWeb) {
          remoteAudioRenderers[event.track!.id!]?.muted = false;
        }
      }

      if (event.track != null && event.flowing == true && event.track?.kind == 'video') {
        MediaStream temp = await createLocalMediaStream(event.track!.id!);
        setState(() {
          remoteVideoRenderers.putIfAbsent(event.track!.id!, () => RTCVideoRenderer());
          remoteVideoStreams.putIfAbsent(event.track!.id!, () => temp);
        });
        await remoteVideoRenderers[event.track!.id!]?.initialize();
        await remoteVideoStreams[event.track!.id!]?.addTrack(event.track!);
        remoteVideoRenderers[event.track!.id!]?.srcObject = remoteVideoStreams[event.track!.id!];
        if (kIsWeb) {
          remoteVideoRenderers[event.track!.id!]?.muted = false;
        }
      }
    });
    plugin.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is StreamingPluginPreparingEvent) {
        await plugin.handleRemoteJsep(event.jsep);
        await plugin.startStream();
        setState(() {
          _loader = false;
        });
      }
      if (data is StreamingPluginStoppingEvent) {
        destroy();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initJanusClient();
  }

  cleanUpWebRTCStuff() {
    remoteAudioStreams.forEach((key, value) {
      stopAllTracksAndDispose(value);
    });
    remoteVideoStreams.forEach((key, value) {
      stopAllTracksAndDispose(value);
    });
    remoteAudioRenderers.forEach((key, value) async {
      value.srcObject = null;
      await value.dispose();
    });
    remoteVideoRenderers.forEach((key, value) async {
      value.srcObject = null;
      await value.dispose();
    });
  }

  destroy() async {
    cleanUpWebRTCStuff();
    await plugin.stopStream();
    await plugin.dispose();
    session.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        ...remoteAudioRenderers.entries.map((e) => e.value).map((e) => RTCVideoView(e)).toList(),
        Column(
          children: [
            Expanded(
                child: GridView.count(
              crossAxisCount: 1,
              childAspectRatio: MediaQuery.of(context).size.width / (MediaQuery.of(context).size.height / (remoteVideoRenderers.length > 0 ? remoteVideoRenderers.length : 1)),
              mainAxisSpacing: 0,
              crossAxisSpacing: 5,
              shrinkWrap: true,
              children: remoteVideoRenderers.entries
                  .map((e) => e.value)
                  .map((e) => RTCVideoView(
                        e,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      ))
                  .toList(),
            )),
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
                                Navigator.of(context).pop();
                              })),
                      padding: EdgeInsets.all(10),
                    ),
                    Padding(
                      child: CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 30,
                          child: IconButton(
                              icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                              color: Colors.white,
                              onPressed: () async {
                                if (isMuted) {
                                  setState(() {
                                    isMuted = false;
                                  });
                                } else {
                                  setState(() {
                                    isMuted = true;
                                  });
                                }
                                var transrecievers = await plugin.webRTCHandle?.peerConnection?.transceivers;
                                transrecievers?.forEach((element) {
                                  if (element.receiver.track?.kind == 'audio') {
                                    element.receiver.track?.enabled = !isMuted;
                                  }
                                });
                              })),
                      padding: EdgeInsets.all(10),
                    ),
                    Padding(
                      child: CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 30,
                          child: IconButton(
                              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                              color: Colors.white,
                              onPressed: () async {
                                if (isPlaying) {
                                  await plugin.pauseStream();
                                  setState(() {
                                    isPlaying = false;
                                  });
                                } else {
                                  setState(() {
                                    isPlaying = true;
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
    super.dispose();
    destroy();
  }
}
