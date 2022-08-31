import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:janus_client_example/conf.dart';
import 'package:janus_client_example/Helper.dart';

class TypedScreenShareVideoRoomV2Unified extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<TypedScreenShareVideoRoomV2Unified> {
  late JanusClient j;
  Map<int, RemoteStream> remoteStreams = {};

  late RestJanusTransport rest;
  late WebSocketJanusTransport ws;
  late JanusSession session;
  late JanusVideoRoomPlugin plugin;
  JanusVideoRoomPlugin? remoteHandle;
  late int myId;
  MediaStream? myStream;
  int myRoom = 1234;
  Map<int, dynamic> feedStreams = {};
  Map<int?, dynamic> subscriptions = {};
  Map<int, dynamic> feeds = {};
  Map<String, int> subStreams = {};
  Map<int, MediaStream?> mediaStreams = {};
  bool roomJoined = false;
  bool screenSharing = false;
  RemoteStream? zoomStream;

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await initialize();
  }

  initialize() async {
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
    j = JanusClient(
        transport: ws,
        stringIds: false,
        isUnifiedPlan: true,
        iceServers: [
          RTCIceServer(
              urls: "stun:stun1.l.google.com:19302",
              username: "",
              credential: "")
        ]);
    session = await j.createSession();
    plugin = await session.attach<JanusVideoRoomPlugin>();
  }

  subscribeTo(List<Map<String, dynamic>> sources) async {
    if (sources.length == 0) return;
    var streams = (sources)
        .map((e) => PublisherStream(mid: e['mid'], feed: e['feed']))
        .toList();
    if (remoteHandle != null) {
      await remoteHandle?.subscribeToStreams(streams);
      return;
    }
    remoteHandle = await session.attach<JanusVideoRoomPlugin>();
    print(sources);
    var start = await remoteHandle?.joinSubscriber(myRoom, streams: streams);
    remoteHandle?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomAttachedEvent) {
        print('Attached event');
        data.streams?.forEach((element) {
          if (element.mid != null && element.feedId != null) {
            subStreams[element.mid!] = element.feedId!;
          }
          // to avoid duplicate subscriptions
          if (subscriptions[element.feedId] == null)
            subscriptions[element.feedId] = {};
          subscriptions[element.feedId][element.mid] = true;
        });
        print('substreams');
        print(subStreams);
      }
      if (event.jsep != null) {
        await remoteHandle?.handleRemoteJsep(event.jsep);
        await start!();
      }
    });
    remoteHandle?.remoteTrack?.listen((event) async {
      String mid = event.mid!;
      if (subStreams[mid] != null) {
        int feedId = subStreams[mid]!;
        if (!remoteStreams.containsKey(feedId)) {
          RemoteStream temp = RemoteStream(feedId.toString());
          await temp.init();
          setState(() {
            remoteStreams.putIfAbsent(feedId, () => temp);
          });
        }
        if (event.track != null && event.flowing == true) {
          remoteStreams[feedId]?.video.addTrack(event.track!);
          remoteStreams[feedId]?.videoRenderer.srcObject =
              remoteStreams[feedId]?.video;
          remoteStreams[feedId]?.videoRenderer.muted = false;
        }
      }
    });
    return;
  }

  Future<void> joinRoom() async {
    myStream = await plugin.initializeMediaDevices(
        useDisplayMediaDevices: true,
        mediaConstraints: {"video": true, "audio": true});
    RemoteStream mystr = RemoteStream('0');
    await mystr.init();
    mystr.videoRenderer.srcObject = myStream;
    setState(() {
      remoteStreams.putIfAbsent(0, () => mystr);
    });
    await plugin.joinPublisher(
      myRoom,
      displayName: "Shivansh",
    );
    var transreciever = await plugin.webRTCHandle?.peerConnection?.transceivers;
    transreciever?.forEach((element) {
      element.sender.track?.onEnded = () {
        print('screen share ended');
        setState(() {
          screenSharing = false;
        });
      };
    });
    plugin.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        (await plugin.publishMedia(bitrate: 3000000));
        List<Map<String, dynamic>> publisherStreams = [];
        for (Publishers publisher in data.publishers ?? []) {
          for (Streams stream in publisher.streams ?? []) {
            feedStreams[publisher.id!] = {
              "id": publisher.id,
              "display": publisher.display,
              "streams": publisher.streams
            };
            publisherStreams.add({"feed": publisher.id, ...stream.toJson()});
            if (publisher.id != null && stream.mid != null) {
              subStreams[stream.mid!] = publisher.id!;
              print("substreams is:");
              print(subStreams);
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
            publisherStreams.add({"feed": publisher.id, ...stream.toJson()});
            if (publisher.id != null && stream.mid != null) {
              subStreams[stream.mid!] = publisher.id!;
              print("substreams is:");
              print(subStreams);
            }
          }
        }
        print('got new publishers');
        print(publisherStreams);
        subscribeTo(publisherStreams);
      }
      if (data is VideoRoomLeavingEvent) {
        print('publisher is leaving');
        print(data.leaving);
        unSubscribeStream(data.leaving!);
      }
      if (data is VideoRoomConfigured) {
        print('typed event with jsep' + event.jsep.toString());
        await plugin.handleRemoteJsep(event.jsep);
        setState(() {
          roomJoined = true;
          screenSharing = true;
        });
      }
    });
  }

  Future<void> unSubscribeStream(int id) async {
// Unsubscribe from this publisher
    var feed = this.feedStreams[id];
    if (feed == null) return;
    this.feedStreams.remove(id);
    await remoteStreams[id]?.dispose();
    remoteStreams.remove(id);
    MediaStream? streamRemoved = this.mediaStreams.remove(id);
    streamRemoved?.getTracks().forEach((element) async {
      await element.stop();
    });
    var unsubscribe = {
      "request": "unsubscribe",
      "streams": [
        {feed: id}
      ]
    };
    if (remoteHandle != null)
      await remoteHandle?.send(data: {"message": unsubscribe});
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
      value.dispose();
    });
    setState(() {
      remoteStreams = {};
    });
    subStreams.clear();
    subscriptions.clear();
    // stop all tracks and then dispose
    myStream?.getTracks().forEach((element) async {
      await element.stop();
    });
    await myStream?.dispose();
    await plugin.dispose();
    await remoteHandle?.dispose();
  }

  Future<void> screenShareAgain() async {
    var transreciever = await plugin.webRTCHandle?.peerConnection?.transceivers;
    MediaStream stream = await navigator.mediaDevices
        .getDisplayMedia({"video": true, "audio": true});
    remoteStreams[0]?.videoRenderer.srcObject = stream;
    transreciever?.forEach((element) {
      element.sender.track?.onMute = () {};
      if (element.sender.track?.kind == "video") {
        stream.getVideoTracks().forEach((track) {
          element.sender.replaceTrack(track);
        });
      }
      if (element.sender.track?.kind == "audio") {
        stream.getAudioTracks().forEach((track) {
          element.sender.replaceTrack(track);
        });
      }
    });
    setState(() {
      screenSharing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                icon: Icon(
                  roomJoined && screenSharing
                      ? Icons.play_circle_outline
                      : Icons.screen_share,
                  color: Colors.greenAccent,
                ),
                onPressed: roomJoined && screenSharing
                    ? null
                    : () async {
                        if (!roomJoined) {
                          await this.joinRoom();
                        } else if (roomJoined && !screenSharing) {
                          screenShareAgain();
                        }
                      }),
            IconButton(
                icon: Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                onPressed: () async {
                  await callEnd();
                }),
          ],
          title: const Text('janus_client'),
        ),
        body: GridView.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount:
                remoteStreams.entries.map((e) => e.value).toList().length,
            itemBuilder: (context, index) {
              List<RemoteStream> items =
                  remoteStreams.entries.map((e) => e.value).toList();
              RemoteStream remoteStream = items[index];
              return Stack(
                children: [
                  RTCVideoView(remoteStream.videoRenderer,
                      filterQuality: FilterQuality.high,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                        onPressed: () async {
                          var dialog;
                          setState(() {
                            zoomStream = remoteStream;
                          });
                          dialog = await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                    insetPadding: EdgeInsets.zero,
                                    contentPadding: EdgeInsets.zero,
                                    content: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height,
                                      child: Stack(children: [
                                        Positioned.fill(
                                          child: RTCVideoView(
                                              zoomStream!.videoRenderer,
                                              filterQuality: FilterQuality.high,
                                              objectFit: RTCVideoViewObjectFit
                                                  .RTCVideoViewObjectFitContain),
                                        ),
                                        Align(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Flexible(
                                                  child: IconButton(
                                                icon: Icon(Icons.close,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(dialog);
                                                },
                                              ))
                                            ],
                                          ),
                                          alignment: Alignment.topRight,
                                        )
                                      ]),
                                    ));
                              });
                        },
                        icon: Icon(Icons.fit_screen, color: Colors.white),
                        iconSize: 20,
                        splashRadius: 24,
                      ))
                ],
              );
            }));
  }
}
