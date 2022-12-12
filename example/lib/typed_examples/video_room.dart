import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:janus_client_example/conf.dart';
import 'package:janus_client_example/Helper.dart';
import 'package:logging/logging.dart';

class TypedVideoRoomV2Unified extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<TypedVideoRoomV2Unified> {
  late JanusClient j;
  Map<dynamic, List<RemoteStream>> remoteStreams = {};
  Map<dynamic, dynamic> feedStreams = {};
  Map<dynamic, dynamic> subscriptions = {};
  Map<dynamic, dynamic> subStreams = {};
  Map<dynamic, MediaStream?> mediaStreams = {};
  List<SubscriberUpdateStream> subscribeStreams = [];
  List<SubscriberUpdateStream> unSubscribeStreams = [];
  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusVideoRoomPlugin plugin;
  JanusVideoRoomPlugin? remoteHandle;
  RemoteStream? screenShareStream;
  late int myId;
  bool front = true;
  dynamic fullScreenDialog;

  dynamic myRoom = 1234;
  String? myUsername;
  String? myPin;
  TextEditingController username = TextEditingController(text: 'shivansh');
  TextEditingController room = TextEditingController(text: '1234');
  TextEditingController pin = TextEditingController();
  dynamic joiningDialog;
  GlobalKey<FormState> joinForm = GlobalKey();
  bool videoEnabled = true;
  bool audioEnabled = true;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (mounted) {
      await initialize();
    }
  }

  initialize() async {
    ws = WebSocketJanusTransport(url: servermap['servercheap']);
    j = JanusClient(
        transport: ws,
        isUnifiedPlan: true,
        iceServers: [
          RTCIceServer(
              urls: "stun:stun1.l.google.com:19302",
              username: "",
              credential: "")
        ],
        loggerLevel: Level.FINE);
    session = await j.createSession();
  }

  subscribeTo(List<Map<dynamic, dynamic>> sources) async {
    if (sources.length == 0) return;
    var streams = (sources)
        .map((e) => PublisherStream(mid: e['mid'], feed: e['feed']))
        .toList();
    if (remoteHandle != null) {
      await remoteHandle?.update(
          subscribe: subscribeStreams, unsubscribe: unSubscribeStreams);
      subscribeStreams = [];
      unSubscribeStreams = [];
      return;
    }
    remoteHandle = await session.attach<JanusVideoRoomPlugin>();
    remoteHandle?.renegotiationNeeded?.listen((event) async {
      if (remoteHandle?.webRTCHandle?.peerConnection?.signalingState !=
              RTCSignalingState.RTCSignalingStateHaveRemoteOffer ||
          remoteHandle?.webRTCHandle?.peerConnection?.signalingState !=
              RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer) return;
      print('retrying to connect subscribers');
      await remoteHandle?.start(myRoom);
    });
    // remoteHandle?.data?.listen((event) {
    //   print('subscriber data:=>');
    //   print(event.text);
    // });
    // remoteHandle?.onData?.listen((event) {
    //   print('subscriber onData:=>');
    //   print(event.toString());
    // });

    await remoteHandle?.joinSubscriber(myRoom, streams: streams, pin: myPin);
    remoteHandle?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      await remoteHandle?.handleRemoteJsep(event.jsep);
      if (data is VideoRoomUpdatedEvent) {
        print('videoroom updated event triggered');
        await remoteHandle?.start(myRoom);
      }
      if (data is VideoRoomAttachedEvent) {
        data.streams?.forEach((element) {
          if (element.mid != null && element.feedId != null) {
            subStreams[element.mid!] = element.feedId!;
          }
          // to avoid duplicate subscriptions
          if (subscriptions[element.feedId] == null)
            subscriptions[element.feedId] = {};
          subscriptions[element.feedId][element.mid] = true;
        });
        await remoteHandle?.start(myRoom);
      }
    }, onError: (error, trace) {
      print('error');
      print(error.toString());
      if (error is JanusError) {
        print(error.toMap());
      }
    });
    remoteHandle?.remoteTrack?.listen((event) async {
      String mid = event.mid!;
      print({
        'mid': mid,
        'label': event.track?.label,
        'kind': event.track?.kind,
        'id': event.track?.id
      });
      dynamic feedId = subStreams[mid].toString();

      if (subStreams[mid] != null) {
        var finalId = feedId + event.track?.id;
        RemoteStream temp = RemoteStream(finalId);
        await temp.init();
        temp.video.addTrack(event.track!);
        temp.videoRenderer.srcObject = temp.video;
        if (!remoteStreams.containsKey(finalId)) {
          setState(() {
            remoteStreams.putIfAbsent(finalId, () => [temp]);
          });
        } else {
          setState(() {
            var streams = remoteStreams[finalId];
            if (streams != null) {
              streams.add(temp);
            } else {
              streams = [temp];
            }
            remoteStreams.putIfAbsent(finalId, () => streams!);
          });
        }
        if (event.track != null && event.flowing == false) {
          setState(() {
            remoteStreams.remove(finalId);
          });
        }
      }
    });
    return;
  }

  Future<void> joinRoom() async {
    plugin = await session.attach<JanusVideoRoomPlugin>();
    await plugin.initDataChannel();
    plugin.data?.listen((event) {
      print('subscriber data:=>');
      print(event.text);
    });
    await plugin.initializeMediaDevices(
        mediaConstraints: {'video': true, 'audio': false});
    RemoteStream myStream = RemoteStream('0');
    await myStream.init();
    myStream.videoRenderer.srcObject = plugin.webRTCHandle!.localStream;
    setState(() {
      remoteStreams.putIfAbsent(0, () => [myStream]);
    });

    // plugin.data?.listen((event) {
    //   print('publisher data:=>');
    //   print(event.text);
    // });
    // plugin.onData?.listen((event) {
    //   print('publisher onData:=>');
    //   print(event.toString());
    // });
    await plugin.joinPublisher(myRoom, displayName: myUsername, pin: myPin);

    plugin.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        Navigator.of(context).pop(joiningDialog);
        (await plugin.configure(
            bitrate: 3000000,
            descriptions: [
              {'description': 'My webcam', 'mid': '0'}
            ],
            sessionDescription: await plugin.createOffer(
                audioRecv: false,
                audioSend: false,
                videoSend: true,
                videoRecv: false)));
        List<Map<dynamic, dynamic>> publisherStreams = [];
        for (Publishers publisher in data.publishers ?? []) {
          feedStreams[publisher.id!] = {
            "id": publisher.id,
            "display": publisher.display,
            "streams": publisher.streams
          };
          for (Streams stream in publisher.streams ?? []) {
            if (subscriptions[publisher.id] != null &&
                subscriptions[publisher.id]?[stream.mid] == true) {
              continue;
            }
            publisherStreams.add({"feed": publisher.id, ...stream.toMap()});
            if (publisher.id != null && stream.mid != null) {
              subStreams[stream.mid!] = publisher.id!;
            }
          }
        }
        subscribeTo(publisherStreams);
      }
      if (data is VideoRoomNewPublisherEvent) {
        List<Map<String, dynamic>> publisherStreams = [];
        for (Publishers publisher in data.publishers ?? []) {
          feedStreams[publisher.id!] = {
            "id": publisher.id,
            "display": publisher.display,
            "streams": publisher.streams
          };
          for (Streams stream in publisher.streams ?? []) {
            if (subscriptions[publisher.id] != null &&
                subscriptions[publisher.id]?[stream.mid] == true) {
              continue;
            }
            publisherStreams.add({"feed": publisher.id, ...stream.toMap()});
            if (publisher.id != null && stream.mid != null) {
              subStreams[stream.mid!] = publisher.id!;
            }
            if (subscribeStreams
                .where((element) =>
                    element.feed == publisher.id && element.mid == stream.mid)
                .isEmpty) {
              subscribeStreams.add(SubscriberUpdateStream(
                  feed: publisher.id, mid: stream.mid, crossrefid: null));
            }
          }
        }
        subscribeTo(publisherStreams);
      }
      if (data is VideoRoomLeavingEvent) {
        unSubscribeStream(data.leaving!);
      }
      await plugin.handleRemoteJsep(event.jsep);
      // if (data is VideoRoomConfigured) {}
      plugin.handleRemoteJsep(event.jsep);
    }, onError: (error, trace) {
      if (error is JanusError) {
        print(error.toMap());
      }
    });

    plugin.renegotiationNeeded?.listen((event) async {
      if (plugin.webRTCHandle?.peerConnection?.signalingState !=
          RTCSignalingState.RTCSignalingStateStable) return;
      print('retrying to connect publisher');
      var offer = await plugin.createOffer(
          audioRecv: false,
          audioSend: false,
          videoRecv: false,
          videoSend: true);
      await plugin.configure(sessionDescription: offer);
    });
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
                        myPin = pin.text.length > 0 ? pin.text : null;
                        myUsername = username.text;
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
                    decoration: InputDecoration(label: Text('Pin')),
                  )
                ]),
              ),
            );
          }));
        });
  }

  disposeScreenSharing() async {
    await plugin.configure(streams: [
      {'mid': '1', 'send': false}
    ]);
    screenShareStream?.mediaStream?.getTracks().forEach((element) async {
      await element.stop();
    });
    screenShareStream?.mediaStream?.dispose();
    screenShareStream?.videoRenderer.srcObject = null;
    await screenShareStream?.video.dispose();
    await screenShareStream?.videoRenderer.dispose();
    setState(() {
      remoteStreams.remove('screenshare');
    });
  }

  screenShare() async {
    if (screenShareStream != null) {
      await disposeScreenSharing();
      return;
    }
    screenShareStream = RemoteStream('screenshare');
    screenShareStream?.mid = "1";
    await screenShareStream?.init();
    screenShareStream?.mediaStream = await navigator.mediaDevices
        .getDisplayMedia({'video': true, 'audio': false});
    screenShareStream?.mediaStream?.getTracks().forEach((element) async {
      await plugin.webRTCHandle?.peerConnection
          ?.addTrack(element, screenShareStream!.mediaStream!);
    });
    screenShareStream?.videoRenderer.srcObject = screenShareStream?.mediaStream;
    setState(() {
      remoteStreams.putIfAbsent('screenshare', () => [screenShareStream!]);
    });
  }

  mute(String kind, bool enabled) async {
    var senders = await plugin.webRTCHandle?.peerConnection?.getSenders();
    var sender = senders?.where((element) => element.track?.kind == kind);
    sender?.first.track?.enabled = enabled;
  }

  Future<void> unSubscribeStream(int id) async {
// Unsubscribe from this publisher
    var feed = this.feedStreams[id];
    if (feed == null) return;
    this.feedStreams.remove(id);
    remoteStreams[id]?.forEach((element) async {
      await element.dispose();
    });
    remoteStreams.remove(id);
    MediaStream? streamRemoved = this.mediaStreams.remove(id);
    streamRemoved?.getTracks().forEach((element) async {
      await element.stop();
    });
    unSubscribeStreams = (feed['streams'] as List<Streams>).map((stream) {
      return SubscriberUpdateStream(
          feed: id, mid: stream.mid, crossrefid: null);
    }).toList();
    if (remoteHandle != null)
      await remoteHandle?.update(unsubscribe: unSubscribeStreams);
    unSubscribeStreams = [];
    this.subscriptions.remove(id);
  }

  @override
  void dispose() async {
    super.dispose();
    await remoteHandle?.dispose();
    await plugin.dispose();
    session.dispose();
  }

  callEnd() async {
    await plugin.hangup();
    for (int i = 0; i < feedStreams.keys.length; i++) {
      await unSubscribeStream(feedStreams.keys.elementAt(i));
    }
    remoteStreams.forEach((key, value) async {
      value.forEach((element) async {
        await element.dispose();
      });
    });

    await plugin.webRTCHandle!.localStream?.dispose();
    await plugin.dispose();
    await remoteHandle?.dispose();
    remoteHandle = null;
    setState(() {
      remoteStreams.clear();
      feedStreams.clear();
      subStreams.clear();
      subscriptions.clear();
      mediaStreams.clear();
    });
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
                  await this.showJoiningDialog();
                }),
            IconButton(
                icon: Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                onPressed: () async {
                  await callEnd();
                }),
            IconButton(
                icon: Icon(
                  screenShareStream == null
                      ? Icons.screen_share
                      : Icons.stop_screen_share,
                  color: Colors.green,
                ),
                onPressed: () async {
                  await screenShare();
                }),
            IconButton(
                icon: Icon(
                  audioEnabled ? Icons.mic : Icons.mic_off,
                  color: Colors.green,
                ),
                onPressed: () async {
                  setState(() {
                    audioEnabled = !audioEnabled;
                  });
                  await mute('audio', audioEnabled);
                }),
            IconButton(
                icon: Icon(
                  videoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: Colors.green,
                ),
                onPressed: () async {
                  setState(() {
                    videoEnabled = !videoEnabled;
                  });
                  await mute('video', videoEnabled);
                }),
            IconButton(
                icon: Icon(
                  Icons.switch_camera,
                  color: Colors.white,
                ),
                onPressed: () async {
                  setState(() {
                    front = !front;
                  });
                  await plugin.switchCamera(
                      deviceId: await getCameraDeviceId(front));
                  RemoteStream myStream = RemoteStream('0');
                  await myStream.init();
                  myStream.videoRenderer.srcObject =
                      plugin.webRTCHandle!.localStream;
                  setState(() {
                    remoteStreams.remove(0);
                    remoteStreams[0] = [myStream];
                  });
                }),
            IconButton(
                icon: Icon(
                  Icons.send_sharp,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await plugin.sendData("cool");
                  await remoteHandle?.sendData("cool");
                })
          ],
          title: const Text('janus_client'),
        ),
        body: GridView.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount:
                remoteStreams.entries.map((e) => e.value).toList().length,
            itemBuilder: (context, index) {
              List<RemoteStream> items = remoteStreams.entries
                  .map((e) => e.value.toList())
                  .expand((element) => element)
                  .toList();
              RemoteStream remoteStream = items[index];
              return Stack(
                children: [
                  RTCVideoView(remoteStream.videoRenderer,
                      filterQuality: FilterQuality.none,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      mirror: true),
                  Align(
                    alignment: AlignmentDirectional.bottomEnd,
                    child: IconButton(
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
                                                Navigator.of(context)
                                                    .pop(fullScreenDialog);
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
                  )
                ],
              );
            }));
  }
}
