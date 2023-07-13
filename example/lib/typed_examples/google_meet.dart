import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:janus_client_example/conf.dart';
import 'package:logging/logging.dart';

import '../util.dart';

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

  initLocalMediaRenderer() {
    localScreenSharingRenderer = StreamRenderer('localScreenShare');
    localVideoRenderer = StreamRenderer('local');
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
        (await videoPlugin.configure(bitrate: 3000000, sessionDescription: await videoPlugin.createOffer(audioRecv: false, videoRecv: false)));
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
    ws = WebSocketJanusTransport(url: servermap['servercheap']);
    client = JanusClient(transport: ws!, isUnifiedPlan: true, iceServers: [RTCIceServer(urls: "stun:stun1.l.google.com:19302", username: "", credential: "")], loggerLevel: Level.FINE);
    session = await client?.createSession();
    initLocalMediaRenderer();
  }

  Future<void> unSubscribeTo(int id) async {
    var feed = videoState.feedIdToDisplayStreamsMap[id];
    if (feed == null) return;
    setState(() {
      videoState.streamsToBeRendered.remove(id.toString());
    });
    videoState.feedIdToDisplayStreamsMap.remove(id.toString());
    await videoState.streamsToBeRendered[id]?.dispose();
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
          videoState.subStreamsToFeedIdMap[element['mid']] = element;
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
        int? feedId = videoState.subStreamsToFeedIdMap[event.mid]?['feed_id'];
        String? displayName = videoState.feedIdToDisplayStreamsMap[feedId]?['display'];
        if (feedId != null) {
          if (videoState.streamsToBeRendered.containsKey(feedId.toString()) && event.track?.kind == "audio") {
            var existingRenderer = videoState.streamsToBeRendered[feedId.toString()];
            existingRenderer?.mediaStream?.addTrack(event.track!);
            existingRenderer?.videoRenderer.srcObject = existingRenderer.mediaStream;
            existingRenderer?.videoRenderer.muted = false;
            setState(() {});
          }
          if (!videoState.streamsToBeRendered.containsKey(feedId.toString()) && event.track?.kind == "video") {
            var localStream = StreamRenderer(feedId.toString());
            await localStream.init();
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
        if (stream['disabled'] != null) {
          print("Disabled stream:");
          // Unsubscribe
          if (removed == null) removed = [];
          removed.add({
            'feed': stream['id'], // This is mandatory
            'mid': stream['mid'] // This is optional (all streams, if missing)
          });
          videoState.feedIdToMidSubscriptionMap[stream['id']]?.remove(stream['mid']);
          videoState.feedIdToMidSubscriptionMap.remove(stream['id']);
          continue;
        }
        if (videoState.feedIdToMidSubscriptionMap[stream['id']] != null && videoState.feedIdToMidSubscriptionMap[stream['id']][stream['mid']] == true) {
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
    StreamRenderer renderer = videoState.streamsToBeRendered[feedId.toString()]!;
    setState(() {
      if (kind == 'audio') {
        renderer.isAudioMuted = muted;
      } else {
        renderer.isVideoMuted = muted;
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
            manageMuteUIEvents(stream['mid'], stream['type'], true);
          } else {
            manageMuteUIEvents(stream['mid'], stream['type'], false);
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
      await videoPlugin?.configure(sessionDescription: offer);
    });
    screenPlugin?.renegotiationNeeded?.listen((event) async {
      if (screenPlugin?.webRTCHandle?.peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) return;
      print('retrying to connect publisher');
      var offer = await screenPlugin?.createOffer(audioRecv: false, videoRecv: false);
      await screenPlugin?.configure(sessionDescription: offer);
    });
  }

  joinRoom() async {
    myId = DateTime.now().millisecondsSinceEpoch;
    initLocalMediaRenderer();
    videoPlugin = await attachPlugin(pop: true);
    eventMessagesHandler();
    await localVideoRenderer.init();
    localVideoRenderer.mediaStream = await videoPlugin?.initializeMediaDevices(simulcastSendEncodings: [
      RTCRtpEncoding(active: true, rid: 'h', maxBitrate: 4000000),
      RTCRtpEncoding(active: true, rid: 'm', maxBitrate: 1000000, scaleResolutionDownBy: 2),
      RTCRtpEncoding(active: true, rid: 'l', maxBitrate: 1000000, scaleResolutionDownBy: 3),
    ], mediaConstraints: {
      'video': {
        'width': {'ideal': 1920},
        'height': {'ideal': 1080}
      },
      'audio': true
    });
    localVideoRenderer.videoRenderer.srcObject = localVideoRenderer.mediaStream;
    localVideoRenderer.publisherName = "You";
    localVideoRenderer.publisherId = myId.toString();
    localVideoRenderer.videoRenderer.onResize = () {
      // to update widthxheight when it renders
      setState(() {});
    };
    setState(() {
      videoState.streamsToBeRendered.putIfAbsent('local', () => localVideoRenderer);
    });
    await videoPlugin?.joinPublisher(myRoom, displayName: username.text, id: myId, pin: myPin);
  }

  screenShare() async {
    setState(() {
      screenSharing = true;
    });
    initLocalMediaRenderer();
    screenPlugin = await session?.attach<JanusVideoRoomPlugin>();
    screenPlugin?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        myPvtId = data.privateId;
        (await screenPlugin?.configure(bitrate: 3000000, sessionDescription: await screenPlugin?.createOffer(audioRecv: false, videoRecv: false)));
      }
      if (data is VideoRoomLeavingEvent) {
        unSubscribeTo(data.leaving!);
      }
      if (data is VideoRoomUnPublishedEvent) {
        unSubscribeTo(data.unpublished);
      }
      screenPlugin?.handleRemoteJsep(event.jsep);
    });
    await localScreenSharingRenderer.init();
    localScreenSharingRenderer.publisherId = myId.toString();
    localScreenSharingRenderer.mediaStream = await screenPlugin?.initializeMediaDevices(mediaConstraints: {
      'video': true,
      'audio': true
    }, simulcastSendEncodings: [
      RTCRtpEncoding(active: true, rid: 'h', maxBitrate: 4000000),
      RTCRtpEncoding(active: true, rid: 'm', maxBitrate: 1000000, scaleResolutionDownBy: 2),
      RTCRtpEncoding(active: true, rid: 'l', maxBitrate: 1000000, scaleResolutionDownBy: 3),
    ], useDisplayMediaDevices: true);
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
    await localVideoRenderer.init();
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

  @override
  void dispose() async {
    super.dispose();
    session?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
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
                color: Colors.white,
              ),
              onPressed: joined ? switchCamera : null)
        ],
        title: const Text('google meet clone'),
      ),
      body: GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemCount: videoState.streamsToBeRendered.entries.length,
          itemBuilder: (context, index) {
            List<StreamRenderer> items = videoState.streamsToBeRendered.entries.map((e) => e.value).toList();
            StreamRenderer remoteStream = items[index];
            return Stack(
              children: [
                Visibility(
                  visible: remoteStream.isVideoMuted == false,
                  replacement: Container(
                    child: Center(
                      child: Text("Video Paused By " + remoteStream.publisherName!, style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  child: Stack(children: [
                    RTCVideoView(
                      remoteStream.videoRenderer,
                      filterQuality: FilterQuality.none,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ),
                    Visibility(
                      child: PositionedDirectional(
                          child: ToggleButtons(
                            direction: Axis.horizontal,
                            onPressed: (int index) async {
                              setState(() {
                                // The button that is tapped is set to true, and the others to false.
                                for (int i = 0; i < remoteStream.selectedQuality.length; i++) {
                                  remoteStream.selectedQuality[i] = i == index;
                                }
                              });
                              await remotePlugin?.send(data: {'request': "configure", 'mid': remoteStream.mid, 'substream': index});
                            },
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            selectedBorderColor: Colors.red[700],
                            selectedColor: Colors.white,
                            fillColor: Colors.red[200],
                            color: Colors.red[400],
                            constraints: const BoxConstraints(
                              minHeight: 20.0,
                              minWidth: 50.0,
                            ),
                            isSelected: remoteStream.selectedQuality,
                            children: [Text('Low'), Text('Medium'), Text('High')],
                          ),
                          top: 120,
                          start: 20),
                      visible: remoteStream.publisherId != myId.toString(),
                    ),
                    Align(
                      child: Text('${remoteStream.videoRenderer.videoWidth}X${remoteStream.videoRenderer.videoHeight}'),
                      alignment: Alignment.bottomLeft,
                    )
                  ]),
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
                                            child: RTCVideoView(
                                              remoteStream.videoRenderer,
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
