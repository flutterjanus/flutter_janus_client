import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:janus_client_example/conf.dart';
import 'package:janus_client_example/Helper.dart';
import 'package:logging/logging.dart';

@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  // FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class TypedScreenShareVideoRoomV2Unified extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<TypedScreenShareVideoRoomV2Unified> {
  late JanusClient j;
  Map<dynamic, RemoteStream> remoteStreams = {};
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
  dynamic fullScreenDialog;
  late int myId;
  bool front = true;
  dynamic myRoom = 1234;

  void _initForegroundTask() {
    if (WebRTC.platformIsAndroid) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'notification_channel_id',
          channelName: 'Foreground Notification',
          channelDescription:
              'This notification appears when the foreground service is running.',
          channelImportance: NotificationChannelImportance.HIGH,
          priority: NotificationPriority.HIGH,
          iconData: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
          buttons: [
            const NotificationButton(id: 'sendButton', text: 'Send'),
            const NotificationButton(id: 'testButton', text: 'Test'),
          ],
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 5000,
          isOnceEvent: false,
          autoRunOnBoot: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    initialize();
  }

  initialize() async {
    ws = WebSocketJanusTransport(url: servermap['janus_ws']);
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
    remoteHandle?.initDataChannel();
    remoteHandle?.data?.listen((event) {
      print('subscriber data:=>');
      print(event.text);
    });
    remoteHandle?.webRTCHandle?.peerConnection?.onRenegotiationNeeded =
        () async {
      await remoteHandle?.start(myRoom);
    };
    await remoteHandle?.joinSubscriber(myRoom, streams: streams);
    remoteHandle?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;

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
      }
      if (event.jsep != null) {
        await remoteHandle?.handleRemoteJsep(event.jsep);
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
      if (subStreams[mid] != null) {
        dynamic feedId = subStreams[mid]!;
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
          if (kIsWeb) {
            remoteStreams[feedId]?.videoRenderer.muted = false;
          }
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
    if (WebRTC.platformIsAndroid) {
      var reqResult = await FlutterForegroundTask.startService(
        notificationTitle: 'ScreenSharing',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }
    await plugin.initializeMediaDevices(
        mediaConstraints: {'video': true, 'audio': true},
        useDisplayMediaDevices: true);
    RemoteStream myStream = RemoteStream('0');
    await myStream.init();
    myStream.videoRenderer.srcObject = plugin.webRTCHandle!.localStream;
    setState(() {
      remoteStreams.putIfAbsent(0, () => myStream);
    });
    await plugin.joinPublisher(myRoom, displayName: "Shivansh");
    plugin.webRTCHandle?.peerConnection?.onRenegotiationNeeded = () async {
      var offer = await plugin.createOffer(
          audioRecv: false, audioSend: true, videoRecv: false, videoSend: true);
      await plugin.configure(sessionDescription: offer);
    };
    plugin.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        (await plugin.publishMedia(bitrate: 3000000));
        List<Map<dynamic, dynamic>> publisherStreams = [];
        for (Publishers publisher in data.publishers ?? []) {
          feedStreams[publisher.id!] = {
            "id": publisher.id,
            "display": publisher.display,
            "streams": publisher.streams
          };
          for (Streams stream in publisher.streams ?? []) {
            feedStreams[publisher.id!] = {
              "id": publisher.id,
              "display": publisher.display,
              "streams": publisher.streams
            };
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
            publisherStreams.add({"feed": publisher.id, ...stream.toMap()});
            if (publisher.id != null && stream.mid != null) {
              subStreams[stream.mid!] = publisher.id!;
            }
            subscribeStreams.add(SubscriberUpdateStream(
                feed: publisher.id, mid: stream.mid, crossrefid: null));
          }
        }
        subscribeTo(publisherStreams);
      }
      if (data is VideoRoomLeavingEvent) {
        unSubscribeStream(data.leaving!);
      }
      // if (data is VideoRoomConfigured) {}
      plugin.handleRemoteJsep(event.jsep);
    }, onError: (error, trace) {
      if (error is JanusError) {
        print(error.toMap());
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
      value.dispose();
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
                  await this.joinRoom();
                }),
            IconButton(
                icon: Icon(
                  Icons.call_end,
                  color: Colors.red,
                ),
                onPressed: () async {
                  await callEnd();
                  if (WebRTC.platformIsAndroid) {
                    await FlutterForegroundTask.stopService();
                  }
                }),
          ],
          title: const Text('janus_client'),
        ),
        body: GridView.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
            itemCount:
                remoteStreams.entries.map((e) => e.value).toList().length,
            itemBuilder: (context, index) {
              List<RemoteStream> items =
                  remoteStreams.entries.map((e) => e.value).toList();
              RemoteStream remoteStream = items[index];
              return Stack(
                children: [
                  RTCVideoView(
                    remoteStream.videoRenderer,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
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
