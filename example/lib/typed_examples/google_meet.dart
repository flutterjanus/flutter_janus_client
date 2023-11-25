import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:janus_client_example/conf.dart';
import 'package:logging/logging.dart';

import '../util.dart';

class VideoView extends StatefulWidget {
  final StreamRenderer remoteStream;
  final int? myId;
  final Function(int index) onSubStreamChange;
  final Function(int index) onTemporalStreamChange;
  const VideoView({Key? key, required this.onSubStreamChange, required this.onTemporalStreamChange, required this.myId, required this.remoteStream}) : super(key: key);
  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.remoteStream.isVideoMuted == false,
      replacement: Container(
        child: Center(
          child: Text("Video Paused By " + widget.remoteStream.publisherName!, style: TextStyle(color: Colors.white)),
        ),
      ),
      child: Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: RTCVideoView(
            widget.remoteStream.videoRenderer,
            filterQuality: FilterQuality.none,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
        Visibility(
          child: PositionedDirectional(
              child: Column(children: [
                ToggleButtons(
                  direction: Axis.horizontal,
                  onPressed: widget.onSubStreamChange,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedBorderColor: Colors.red[700],
                  selectedColor: Colors.white,
                  fillColor: Colors.red[200],
                  color: Colors.red[400],
                  constraints: const BoxConstraints(
                    minHeight: 20.0,
                    minWidth: 50.0,
                  ),
                  isSelected: widget.remoteStream.subStreamButtonState,
                  children: [Text('Low'), Text('Medium'), Text('High')],
                ),
                ToggleButtons(
                  direction: Axis.horizontal,
                  onPressed: widget.onTemporalStreamChange,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedBorderColor: Colors.red[700],
                  selectedColor: Colors.white,
                  fillColor: Colors.red[200],
                  color: Colors.red[400],
                  constraints: const BoxConstraints(
                    minHeight: 20.0,
                    minWidth: 50.0,
                  ),
                  isSelected: widget.remoteStream.temporalButtonState,
                  children: [Text('T0'), Text('T1')],
                )
              ]),
              top: 10,
              start: 10),
          visible: widget.remoteStream.publisherId != widget.myId.toString(),
        ),
        Align(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text('${widget.remoteStream.videoRenderer.videoWidth}X${widget.remoteStream.videoRenderer.videoHeight}'),
          ),
          alignment: Alignment.bottomLeft,
        )
      ]),
    );
  }
}

class GoogleMeet extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<GoogleMeet> {
  JanusClient? client;
  RestJanusTransport? rest;
  WebSocketJanusTransport? ws;
  JanusSession? session;
  JanusSession? session2;

  bool front = true;
  dynamic fullScreenDialog;
  bool screenSharing = false;
  bool joined = false;
  String? myUsername;
  String? myPin;
  TextEditingController username = TextEditingController(text: 'shivansh');
  TextEditingController room = TextEditingController(text: '1234');
  TextEditingController pin = TextEditingController();
  dynamic joiningDialog;
  GlobalKey<FormState> joinForm = GlobalKey();
  bool videoEnabled = true;
  bool audioEnabled = true;
  int? myId;
  int? myPvtId;
  get screenShareId => myId! + int.parse("1");
  int? myRoom = 1234;
  JanusVideoRoomPlugin? videoPlugin;
  JanusVideoRoomPlugin? screenPlugin;
  JanusVideoRoomPlugin? remotePlugin;
  late StreamRenderer localScreenSharingRenderer;
  late StreamRenderer localVideoRenderer;

  VideoRoomPluginStateManager videoState = VideoRoomPluginStateManager();

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (mounted) {
      await initialize();
    }
  }

  attachPlugin({bool pop = false}) async {
    JanusVideoRoomPlugin? videoPlugin = await session?.attach<JanusVideoRoomPlugin>();
    videoPlugin?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        myPvtId = data.privateId;
        if (pop) {
          Navigator.of(context).pop(joiningDialog);
        }
        (await videoPlugin.configure(bitrate: 0, sessionDescription: await videoPlugin.createOffer(audioRecv: false, videoRecv: false)));
      }
      if (data is VideoRoomLeavingEvent) {
        unSubscribeTo(data.leaving!);
      }
      if (data is VideoRoomUnPublishedEvent) {
        unSubscribeTo(data.unpublished);
      }
      videoPlugin.handleRemoteJsep(event.jsep);
    });
    return videoPlugin;
  }

  initialize() async {
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    client = JanusClient(
        transport: ws!,
        withCredentials: true,
        apiSecret: "janusrocks",
        isUnifiedPlan: true,
        iceServers: [RTCIceServer(urls: "stun:stun1.l.google.com:19302", username: "", credential: "")],
        loggerLevel: Level.INFO);
    session = await client?.createSession();
  }

  Future<void> unSubscribeTo(int id) async {
    var feed = videoState.feedIdToDisplayStreamsMap[id];
    if (feed == null) return;
    videoState.feedIdToDisplayStreamsMap.remove(id.toString());
    await videoState.streamsToBeRendered[id]?.dispose();
    setState(() {
      videoState.streamsToBeRendered.remove(id.toString());
    });
    var unsubscribeStreams = (feed['streams'] as List<dynamic>).map((stream) {
      return SubscriberUpdateStream(feed: id, mid: stream['mid'], crossrefid: null);
    }).toList();
    if (remotePlugin != null) await remotePlugin?.update(unsubscribe: unsubscribeStreams);
    videoState.feedIdToMidSubscriptionMap.remove(id);
  }

  subscribeTo(List<List<Map>> sources) async {
    if (sources.isEmpty) {
      return;
    }
    if (remotePlugin == null) {
      remotePlugin = await session?.attach<JanusVideoRoomPlugin>();
      remotePlugin?.messages?.listen((payload) async {
        JanusEvent event = JanusEvent.fromJson(payload.event);
        List<dynamic>? streams = event.plugindata?.data['streams'];
        streams?.forEach((element) {
          videoState.subStreamsToFeedIdMap[element['mid'].toString()] = element;
          // to avoid duplicate subscriptions
          if (videoState.feedIdToMidSubscriptionMap[element['feed_id']] == null) videoState.feedIdToMidSubscriptionMap[element['feed_id']] = {};
          videoState.feedIdToMidSubscriptionMap[element['feed_id']][element['mid']] = true;
        });
        if (payload.jsep != null) {
          await remotePlugin?.handleRemoteJsep(payload.jsep);
          await remotePlugin?.start(myRoom);
        }
      });

      remotePlugin?.remoteTrack?.listen((event) async {
        print({'mid': event.mid, 'flowing': event.flowing, 'id': event.track?.id, 'kind': event.track?.kind});
        if (event.mid != null && event.flowing != null && event.track != null) {
          await manageMuteUIEvents(event.mid!, event.track!.kind!, !event.flowing!);
        }
        int? feedId = videoState.subStreamsToFeedIdMap[event.mid.toString()]?['feed_id'];
        String? displayName = videoState.feedIdToDisplayStreamsMap[feedId]?['display'];
        if (feedId != null) {
          if (videoState.streamsToBeRendered.containsKey(feedId.toString()) && event.flowing == true && event.track?.kind == "audio") {
            var existingRenderer = videoState.streamsToBeRendered[feedId.toString()];
            existingRenderer?.mediaStream?.addTrack(event.track!);
            existingRenderer?.videoRenderer.srcObject = existingRenderer.mediaStream;
            existingRenderer?.videoRenderer.muted = false;
            setState(() {});
          }
          if (!videoState.streamsToBeRendered.containsKey(feedId.toString()) && event.flowing == true && event.track?.kind == "video") {
            var localStream = StreamRenderer(feedId.toString());
            await localStream.init(setState);
            localStream.mediaStream = await createLocalMediaStream(feedId.toString());
            localStream.mediaStream?.addTrack(event.track!);
            localStream.videoRenderer.srcObject = localStream.mediaStream;
            localStream.videoRenderer.onResize = () => {setState(() {})};
            localStream.publisherName = displayName;
            localStream.publisherId = feedId.toString();
            localStream.mid = event.mid;
            setState(() {
              videoState.streamsToBeRendered.putIfAbsent(feedId.toString(), () => localStream);
            });
          }
        }
      });
      List<PublisherStream> streams =
          sources.map((e) => e.map((e) => PublisherStream(feed: e['id'], mid: e['mid'], simulcast: e['simulcast']))).expand((element) => element).toList();
      await remotePlugin?.joinSubscriber(myRoom, streams: streams, pin: myPin);
      return;
    }
    List<Map>? added = null, removed = null;
    for (var streams in sources) {
      for (var stream in streams) {
        // If the publisher is VP8/VP9 and this is an older Safari, let's avoid video
        if (stream['disabled'] == true) {
          print("Disabled stream:");
          if (removed == null) removed = [];
          removed.add({
            'feed': stream['id'], // This is mandatory
            'mid': stream['mid'] // This is optional (all streams, if missing)
          });
          videoState.feedIdToMidSubscriptionMap[stream['id']]?.remove(stream['mid']);
          videoState.feedIdToMidSubscriptionMap.remove(stream['id']);
          continue;
        }
        if (videoState.feedIdToMidSubscriptionMap[stream['id']]?[stream['mid']] == true) {
          print("Already subscribed to stream, skipping:");
          continue;
        }
        // Subscribe
        if (added == null) added = [];
        added.add({
          'feed': stream['id'], // This is mandatory
          'mid': stream['mid'] // This is optional (all streams, if missing)
        });
        if (videoState.feedIdToMidSubscriptionMap[stream['id']] == null) videoState.feedIdToMidSubscriptionMap[stream['id']] = {};
        videoState.feedIdToMidSubscriptionMap[stream['id']][stream['mid']] = true;
      }
    }
    if ((added == null || added.length == 0) && (removed == null || removed.length == 0)) {
      // Nothing to do
      return;
    }
    await remotePlugin?.update(
        subscribe: added?.map((e) => SubscriberUpdateStream(feed: e['feed'], mid: e['mid'], crossrefid: null)).toList(),
        unsubscribe: removed?.map((e) => SubscriberUpdateStream(feed: e['feed'], mid: e['mid'], crossrefid: null)).toList());
  }

  manageMuteUIEvents(String mid, String kind, bool muted) async {
    int? feedId = videoState.subStreamsToFeedIdMap[mid]?['feed_id'];
    if (feedId == null) {
      return;
    }
    StreamRenderer? renderer = videoState.streamsToBeRendered[feedId.toString()];
    setState(() {
      if (kind == 'audio') {
        renderer?.isAudioMuted = muted;
      } else {
        renderer?.isVideoMuted = muted;
      }
    });
  }

  attachSubscriberOnPublisherChange(List<dynamic>? publishers) async {
    if (publishers != null) {
      List<List<Map>> sources = [];
      for (Map publisher in publishers) {
        if ([myId, screenShareId].contains(publisher['id'])) {
          continue;
        }
        videoState.feedIdToDisplayStreamsMap[publisher['id']] = {'id': publisher['id'], 'display': publisher['display'], 'streams': publisher['streams']};
        List<Map> mappedStreams = [];
        for (Map stream in publisher['streams'] ?? []) {
          if (stream['disabled'] == true) {
            await manageMuteUIEvents(stream['mid'], stream['type'], true);
          } else {
            await manageMuteUIEvents(stream['mid'], stream['type'], false);
          }
          if (videoState.feedIdToMidSubscriptionMap[publisher['id']] != null && videoState.feedIdToMidSubscriptionMap[publisher['id']]?[stream['mid']] == true) {
            continue;
          }
          stream['id'] = publisher['id'];
          stream['display'] = publisher['display'];
          mappedStreams.add(stream);
        }
        sources.add(mappedStreams);
      }
      await subscribeTo(sources);
    }
  }

  eventMessagesHandler() async {
    videoPlugin?.messages?.listen((payload) async {
      JanusEvent event = JanusEvent.fromJson(payload.event);
      print(event.plugindata?.data);
      List<dynamic>? publishers = event.plugindata?.data['publishers'];
      await attachSubscriberOnPublisherChange(publishers);
    });

    screenPlugin?.messages?.listen((payload) async {
      JanusEvent event = JanusEvent.fromJson(payload.event);
      List<dynamic>? publishers = event.plugindata?.data['publishers'];
      await attachSubscriberOnPublisherChange(publishers);
    });

    videoPlugin?.renegotiationNeeded?.listen((event) async {
      if (videoPlugin?.webRTCHandle?.peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) return;
      print('retrying to connect publisher');
      var offer = await videoPlugin?.createOffer(
        audioRecv: false,
        videoRecv: false,
      );
      await videoPlugin?.configure(sessionDescription: offer, bitrate: 0);
    });
    screenPlugin?.renegotiationNeeded?.listen((event) async {
      if (screenPlugin?.webRTCHandle?.peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) return;
      print('retrying to connect publisher');
      var offer = await screenPlugin?.createOffer(audioRecv: false, videoRecv: false);
      await screenPlugin?.configure(bitrate: 0, sessionDescription: offer);
    });
  }

  joinRoom() async {
    myId = DateTime.now().millisecondsSinceEpoch;
    localVideoRenderer = StreamRenderer('local');
    videoPlugin = await attachPlugin(pop: true);
    await eventMessagesHandler();
    await localVideoRenderer.init(setState);
    localVideoRenderer.mediaStream = await videoPlugin?.initializeMediaDevices(simulcastSendEncodings: [
      RTCRtpEncoding(rid: "h", minBitrate: 2000000, maxBitrate: 2000000, active: true, scalabilityMode: 'L1T2'),
      RTCRtpEncoding(
        rid: "m",
        minBitrate: 1000000,
        maxBitrate: 1000000,
        active: true,
        scalabilityMode: 'L1T2',
        scaleResolutionDownBy: 2,
      ),
      RTCRtpEncoding(
        rid: "l",
        minBitrate: 512000,
        maxBitrate: 512000,
        active: true,
        scalabilityMode: 'L1T2',
        scaleResolutionDownBy: 3,
      ),
    ], mediaConstraints: {
      'video': {'width': 1280, 'height': 720},
      'audio': true
    });
    localVideoRenderer.videoRenderer.srcObject = localVideoRenderer.mediaStream;
    localVideoRenderer.publisherName = "You";
    localVideoRenderer.publisherId = myId.toString();
    setState(() {
      videoState.streamsToBeRendered.putIfAbsent('local', () => localVideoRenderer);
    });
    await videoPlugin?.joinPublisher(myRoom, displayName: username.text, id: myId, pin: myPin);
  }

  screenShare() async {
    setState(() {
      screenSharing = true;
    });
    localScreenSharingRenderer = StreamRenderer('localScreenShare');
    screenPlugin = await session?.attach<JanusVideoRoomPlugin>();
    screenPlugin?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        myPvtId = data.privateId;
        (await screenPlugin?.configure(bitrate: 0, sessionDescription: await screenPlugin?.createOffer(audioRecv: false, videoRecv: false)));
      }
      if (data is VideoRoomLeavingEvent) {
        unSubscribeTo(data.leaving!);
      }
      if (data is VideoRoomUnPublishedEvent) {
        unSubscribeTo(data.unpublished);
      }
      screenPlugin?.handleRemoteJsep(event.jsep);
    });
    await localScreenSharingRenderer.init(setState);
    localScreenSharingRenderer.publisherId = myId.toString();
    localScreenSharingRenderer.mediaStream = await screenPlugin?.initializeMediaDevices(mediaConstraints: {
      'video': {'width': 1920, 'height': 1080},
      'audio': true
    }, useDisplayMediaDevices: true);
    localScreenSharingRenderer.videoRenderer.srcObject = localScreenSharingRenderer.mediaStream;
    localScreenSharingRenderer.publisherName = "Your Screenshare";
    setState(() {
      videoState.streamsToBeRendered.putIfAbsent(localScreenSharingRenderer.id, () => localScreenSharingRenderer);
    });
    await screenPlugin?.joinPublisher(myRoom, displayName: username.text + "_screenshare", id: screenShareId, pin: myPin);
  }

  disposeScreenSharing() async {
    setState(() {
      screenSharing = false;
    });
    await screenPlugin?.unpublish();
    StreamRenderer? rendererRemoved;
    setState(() {
      rendererRemoved = videoState.streamsToBeRendered.remove(localScreenSharingRenderer.id);
    });
    await rendererRemoved?.dispose();
    await screenPlugin?.hangup();
    screenPlugin = null;
  }

  switchCamera() async {
    setState(() {
      front = !front;
    });
    await videoPlugin?.switchCamera(deviceId: await getCameraDeviceId(front));
    localVideoRenderer = StreamRenderer('local');
    await localVideoRenderer.init(setState);
    localVideoRenderer.videoRenderer.srcObject = videoPlugin?.webRTCHandle!.localStream;
    localVideoRenderer.publisherName = "My Camera";
    setState(() {
      videoState.streamsToBeRendered['local'] = localVideoRenderer;
    });
  }

  mute(RTCPeerConnection? peerConnection, String kind, bool enabled) async {
    var transrecievers = (await peerConnection?.getTransceivers())?.where((element) => element.sender.track?.kind == kind).toList();
    if (transrecievers?.isEmpty == true) {
      return;
    }
    await transrecievers?.first.setDirection(enabled ? TransceiverDirection.SendOnly : TransceiverDirection.Inactive);
    // below method mutes/disables mid based on janus but no brief notification is received from janus
    // await videoPlugin?.send(data: {
    //   "request" : "configure",
    //   "streams": [
    //     {"mid": transrecievers?.first.mid, "send": enabled},
    //   ],
    // });
  }

  callEnd() async {
    for (var feed in videoState.feedIdToDisplayStreamsMap.entries) {
      await unSubscribeTo(feed.key);
    }
    videoState.streamsToBeRendered.forEach((key, value) async {
      await value.dispose();
    });
    setState(() {
      videoState.streamsToBeRendered.clear();
      videoState.feedIdToDisplayStreamsMap.clear();
      videoState.subStreamsToFeedIdMap.clear();
      videoState.feedIdToMidSubscriptionMap.clear();
      audioEnabled = true;
      videoEnabled = true;
      this.joined = false;
      this.screenSharing = false;
    });
    await videoPlugin?.hangup();
    if (screenSharing) {
      await screenPlugin?.hangup();
    }
    await videoPlugin?.dispose();
    await screenPlugin?.dispose();
    await remotePlugin?.dispose();
    remotePlugin = null;
    videoPlugin = null;
  }

  Future<dynamic> showJoiningDialog() async {
    joiningDialog = await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              actions: [
                TextButton(
                    onPressed: () async {
                      if (joinForm.currentState?.validate() == true) {
                        myRoom = int.parse(room.text);
                        myPin = pin.text;
                        myUsername = username.text;
                        setState(() {
                          this.joined = true;
                        });
                        await joinRoom();
                      }
                    },
                    child: Text('Join'))
              ],
              insetPadding: EdgeInsets.zero,
              scrollable: true,
              content: Form(
                key: joinForm,
                child: Column(children: [
                  TextFormField(
                    controller: room,
                    validator: (value) {
                      return value == '' ? 'Room is required' : null;
                    },
                    decoration: InputDecoration(label: Text('Room')),
                  ),
                  TextFormField(
                    controller: username,
                    validator: (value) {
                      return value == '' ? 'Username is required' : null;
                    },
                    decoration: InputDecoration(label: Text('Username')),
                  ),
                  TextFormField(
                    controller: pin,
                    obscureText: true,
                    decoration: InputDecoration(label: Text('Pin')),
                  )
                ]),
              ),
            );
          }));
        });
  }

  onSubStreamChange(StreamRenderer remoteStream, index, updateState) async {
    updateState(() {
      remoteStream.subStreamButtonState = remoteStream.subStreamButtonState.map((e) => false).toList();
      remoteStream.subStreamButtonState[index] = true;
      remoteStream.subStream = ConfigureStreamQuality.values[index];
      // The button that is tapped is set to true, and the others to false.
    });
    await remotePlugin?.configure(
      streams: [ConfigureStream(mid: remoteStream.mid, substream: remoteStream.subStream)],
    );
    updateState(() {});
  }

  onTemporalChange(StreamRenderer remoteStream, index, updateState) async {
    updateState(() {
      remoteStream.temporalButtonState = remoteStream.temporalButtonState.map((e) => false).toList();
      remoteStream.temporalButtonState[index] = true;
      remoteStream.temporal = ConfigureStreamQuality.values[index];
    });
    await remotePlugin?.configure(
      streams: [ConfigureStream(mid: remoteStream.mid, temporal: remoteStream.temporal)],
    );
    updateState(() {});
  }

  @override
  void dispose() async {
    super.dispose();
    session?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                icon: Icon(
                  joined ? Icons.call_end : Icons.call,
                  color: joined ? Colors.red : Colors.greenAccent,
                ),
                onPressed: () async {
                  if (joined) {
                    await callEnd();
                    return;
                  }
                  await this.showJoiningDialog();
                }),
            IconButton(
                icon: Icon(
                  !screenSharing ? Icons.screen_share : Icons.stop_screen_share,
                  color: Colors.green,
                ),
                onPressed: joined
                    ? () async {
                        if (screenSharing) {
                          await disposeScreenSharing();
                          return;
                        }
                        await screenShare();
                      }
                    : null),
            IconButton(
                icon: Icon(
                  audioEnabled ? Icons.mic : Icons.mic_off,
                  color: Colors.green,
                ),
                onPressed: joined
                    ? () async {
                        setState(() {
                          audioEnabled = !audioEnabled;
                        });
                        await mute(videoPlugin?.webRTCHandle?.peerConnection, 'audio', audioEnabled);
                        setState(() {
                          localVideoRenderer.isAudioMuted = !audioEnabled;
                        });
                      }
                    : null),
            IconButton(
                icon: Icon(
                  videoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: Colors.green,
                ),
                onPressed: joined
                    ? () async {
                        setState(() {
                          videoEnabled = !videoEnabled;
                        });
                        await mute(videoPlugin?.webRTCHandle?.peerConnection, 'video', videoEnabled);
                      }
                    : null),
            IconButton(
                icon: Icon(
                  Icons.switch_camera,
                  color: Colors.green,
                ),
                onPressed: joined ? switchCamera : null)
          ],
        ),
      ),
      appBar: AppBar(
        leadingWidth: 1,
        leading: SizedBox(),
        actions: [],
        title: const Text('google meet'),
      ),
      body: GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: videoState.streamsToBeRendered.entries.length,
          itemBuilder: (context, index) {
            List<Map<String, dynamic>> items = videoState.streamsToBeRendered.entries.map((e) => {'key': e.key, 'value': e.value}).toList();
            StreamRenderer remoteStream = items[index]['value'];
            return Stack(
              children: [
                VideoView(
                  myId: myId,
                  onSubStreamChange: (index) async {
                    await onSubStreamChange(remoteStream, index, setState);
                  },
                  onTemporalStreamChange: (index) async {
                    await onTemporalChange(remoteStream, index, setState);
                  },
                  remoteStream: remoteStream,
                ),
                Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(remoteStream.publisherName!),
                      Icon(remoteStream.isAudioMuted == true ? Icons.mic_off : Icons.mic),
                      IconButton(
                          onPressed: () async {
                            fullScreenDialog = await showDialog(
                                context: context,
                                builder: ((context) {
                                  return StatefulBuilder(builder: (context, newSetState) {
                                    return AlertDialog(
                                      contentPadding: EdgeInsets.all(10),
                                      insetPadding: EdgeInsets.zero,
                                      content: Container(
                                        width: double.maxFinite,
                                        padding: EdgeInsets.zero,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                                child: Padding(
                                              padding: const EdgeInsets.all(0),
                                              child: VideoView(
                                                myId: myId,
                                                onSubStreamChange: (index) async {
                                                  await onSubStreamChange(remoteStream, index, newSetState);
                                                },
                                                onTemporalStreamChange: (index) async {
                                                  await onTemporalChange(remoteStream, index, newSetState);
                                                },
                                                remoteStream: remoteStream,
                                              ),
                                            )),
                                            Align(
                                              alignment: Alignment.topRight,
                                              child: IconButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop(fullScreenDialog);
                                                  },
                                                  icon: Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  )),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                                }));
                          },
                          icon: Icon(Icons.fullscreen)),
                    ],
                  ),
                )
              ],
            );
          }),
    );
  }
}
