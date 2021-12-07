import 'package:flutter/material.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:janus_client/utils.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

import 'package:janus_client_example/conf.dart';

class VideoRoomV2Unified extends StatefulWidget {
  @override
  _VideoRoomState createState() => _VideoRoomState();
}

class _VideoRoomState extends State<VideoRoomV2Unified> {
  JanusClient j;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  Map<int, RTCVideoRenderer> remoteRenderers = {};
  RestJanusTransport rest;
  WebSocketJanusTransport ws;
  JanusSession session;
  JanusVideoRoomPlugin plugin;
  JanusVideoRoomPlugin remoteFeed;
  int myId;
  int myRoom = 1234;
  dynamic feedStreams = {};
  dynamic subscriptions = {};
  dynamic feeds = {};

  @override
  initState() {
    super.initState();
    initRenderers();
  }

  @override
  void didChangeDependencies() async {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    await initRenderers();
  }

  initRenderers() async {
    setState(() {
      _localRenderer = RTCVideoRenderer();
    });
    await _localRenderer.initialize();
  }

  subscribeTo(sources) async {
    print('inside subscribeTo');
    if (remoteFeed != null) {
      // Prepare the streams to subscribe to, as an array: we have the list of
      // streams the feeds are publishing, so we can choose what to pick or skip
      var subscription = [];
      for (var s in sources) {
        var streams = s;
        for (var i in streams) {
          var stream = i;
          if (stream['disabled'] != null) {
            // Janus.log("Disabled stream:", stream);
            // TODO Skipping for now, we should unsubscribe
            continue;
          }
          if (subscriptions[stream['id']] != null &&
              subscriptions[stream['id']][stream['mid']] != null) {
            print(
                "Already subscribed to stream, skipping:" + stream.toString());
            continue;
          }
          // Find an empty slot in the UI for each new source
          if (feedStreams[stream['id']]['slot'] == null) {
            var slot;
            for (var i = 1; i < 6; i++) {
              if (feeds[i] == null) {
                slot = i;
                feeds[slot] = stream['id'];
                feedStreams[stream['id']]['slot'] = slot;
                feedStreams[stream['id']]['remoteVideos'] = 0;
                break;
              }
            }
          }
          subscription.add({
            'feed': stream['id'], // This is mandatory
            'mid': stream['mid'] // This is optional (all streams, if missing)
          });
          if (subscriptions[stream['id']] == null)
            subscriptions[stream['id']] = {};
          subscriptions[stream['id']][stream['mid']] = true;
        }
      }
      if (subscription.length == 0) {
        // Nothing to do
        return;
      }
      await remoteFeed.send(data: {
        'message': {'request': "subscribe", 'streams': subscription}
      });
      return;
    }
    print('creating remoteFeed');
    remoteFeed = await session.attach(JanusPlugins.VIDEO_ROOM);
    var subscription = [];
    for (var s in sources) {
      var streams = s;
      for (var i in streams) {
        var stream = i;
        //     // If the publisher is VP8/VP9 and this is an older Safari, let's avoid video
        //     if(stream.type === "video" && Janus.webRTCAdapter.browserDetails.browser === "safari" &&
        //     (stream.codec === "vp9" || (stream.codec === "vp8" && !Janus.safariVp8))) {
        // toastr.warning("Publisher is using " + stream.codec.toUpperCase +
        // ", but Safari doesn't support it: disabling video stream #" + stream.mindex);
        // continue;
        // }
        // if(stream.disabled) {
        // Janus.log("Disabled stream:", stream);
        // // TODO Skipping for now, we should unsubscribe
        // continue;
        // }
        // Janus.log("Subscribed to " + stream.id + "/" + stream.mid + "?", subscriptions);
        if (subscriptions[stream['id']] != null &&
            subscriptions[stream['id']][stream['mid']] != null) {
          print("Already subscribed to stream, skipping:" + stream.toString());
          continue;
        }
        subscription.add({
          'feed': stream['id'], // This is mandatory
          'mid': stream['mid'] // This is optional (all streams, if missing)
        });
        if (subscriptions[stream['id']] != null) {
          subscriptions[stream['id']] = {};
          subscriptions[stream['id']][stream['mid']] = true;
        }
      }
    }
    // We wait for the plugin to send us an offer
    var subscribe = {
      'request': "join",
      'room': myRoom,
      'ptype': "subscriber",
      'streams': subscription,
      'private_id': myId
    };
    print('sending subscribe request');
    await remoteFeed.send(data: subscribe);
    remoteFeed.messages.listen((even) async {
      var event = even.event["videoroom"];
      // Janus.debug("Event: " + event);
      if (event != null) {
        if (event == "attached") {
          // creatingFeed = false;
          print("Successfully attached to feed in room " + event["room"]);
        } else if (event == "event") {
          // Check if we got an event on a simulcast-related event from this publisher
          // var mid = msg["mid"];
          // var substream = msg["substream"];
          // var temporal = msg["temporal"];
          // if((substream !== null && substream !== undefined) || (temporal !== null && temporal !== undefined)) {
          //   // Check which this feed this refers to
          //   var sub = subStreams[mid];
          //   var feed = feedStreams[sub.feed_id];
          //   var slot = slots[mid];
          //   if(!simulcastStarted[slot]) {
          //     simulcastStarted[slot] = true;
          //     // Add some new buttons
          //     addSimulcastButtons(slot, true);
          //   }
          //   // We just received notice that there's been a switch, update the buttons
          //   updateSimulcastButtons(slot, substream, temporal);
          // }
        } else {
          // What has just happened?
        }
      }
      if (even.event["streams"] != null) {
        // Update map of subscriptions by mid
        for (var i in even.event["streams"]) {
          var mid = even.event["streams"][i]["mid"];
          // subStreams[mid] = even.event["streams"][i];
          var feed = feedStreams[even.event["streams"][i]["feed_id"]];
          // if(feed && feed.slot) {
          //   slots[mid] = feed.slot;
          //   mids[feed.slot] = mid;
          // }
        }
      }
      if (even.jsep != null) {
        print('handle jsep for subscriber');
        remoteFeed.handleRemoteJsep(even.jsep);
        var jsep =
            await remoteFeed.createAnswer(audioSend: false, videoSend: false);
        var body = {'request': "start", 'room': myRoom};
        await remoteFeed.send(data: body, jsep: jsep);
      }
    });
    remoteFeed.remoteTrack.listen((event) async {
      print('remote track found');
      print(event.toMap());
      setState(() {
        remoteRenderers.putIfAbsent(99, () => new RTCVideoRenderer());
      });
      await remoteRenderers[99].initialize();
      MediaStream mediaStream = await createLocalMediaStream('test');
      mediaStream.addTrack(event.track);
      remoteRenderers[99].srcObject = mediaStream;
    });
  }

  Future<void> initPlatformState() async {
    await initRenderers();
    setState(() {
      ws = WebSocketJanusTransport(url: servermap['janus_ws']);
      j = JanusClient(transport: ws, isUnifiedPlan: true, iceServers: [
        RTCIceServer(
            url: "stun:stun1.l.google.com:19302", username: "", credential: "")
      ]);
    });
    var sess = await j.createSession();
    session = sess;
    plugin = await session.attach<JanusVideoRoomPlugin>(JanusPlugins.VIDEO_ROOM);
    plugin.init();
    final mediaConstraints = <String, dynamic>{'audio': true, 'video': true};
    var stream =
        await plugin.initializeMediaDevices(mediaConstraints: mediaConstraints);
    setState(() {
      remoteRenderers[0] = new RTCVideoRenderer();
    });
    await remoteRenderers[0].initialize();
    setState(() {
      remoteRenderers[0].srcObject = stream;
    });

    var register = {
      "request": "join",
      "ptype": "publisher",
      "room": 1234,
      "display": "Shivansh" + randomString()
    };
    print('got response');
    print(await plugin.send(data: register));
    plugin.messages.listen((msg) async {
      print('on message');
      print(msg);

      if (msg.event['janus'] == 'event') {
        if (msg.jsep != null) {
          print('handling sdp');
          await plugin.handleRemoteJsep(msg.jsep);
        }
        var pluginData = msg.event['plugindata'];
        if (pluginData != null) {
          var data = pluginData['data'];
          if (data != null) {
            if (data["publishers"] != null) {
              List<dynamic> list = data["publishers"];
              var sources = [];
              for (var f in list) {
                print(f);
                var id = f["id"];
                var display = f["display"];
                var streams = f["streams"];
                for (var i in streams) {
                  var stream = i;
                  i["id"] = id;
                  i["display"] = display;
                }
                feedStreams[id] = {id: id, display: display, streams: streams};
                if (sources != null) sources = [];
                sources.add(streams);
              }
              if (sources != null) subscribeTo(sources);
            }
            if (data['videoroom'] == 'event' &&
                    data.containsKey('unpublished') ||
                data.containsKey('leaving')) {
              print('recieved unpublishing event on subscriber handle');
              int leaving = data['leaving'];
              int unpublished = data['unpublished'];
              if (remoteRenderers.containsKey(unpublished)) {
                RTCVideoRenderer renderer;
                setState(() {
                  renderer = remoteRenderers.remove(unpublished);
                });
                renderer.srcObject = null;
              }
              if (remoteRenderers.containsKey(leaving)) {
                RTCVideoRenderer renderer;
                setState(() {
                  renderer = remoteRenderers.remove(leaving);
                });
                renderer.srcObject = null;
              }
            }
            if (data['videoroom'] == 'joined') {
              print('user joined configuring video stream');
              myId = data['id'];
              var publish = {
                "request": "configure",
                "bitrate": 10000000,
                'video': true,
                'audio': true
              };
              RTCSessionDescription offer = await plugin.createOffer(
                  videoRecv: false,
                  audioRecv: false,
                  videoSend: true,
                  audioSend: true);
              print(await plugin.send(data: publish, jsep: offer));
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (plugin != null) {
      plugin.dispose();
    }
    if (session != null) {
      session.dispose();
    }
    cleanUpResources();
  }

  callEnd() async {
    if (plugin != null) {
      await plugin.hangup();
    }

    if (_localRenderer != null) {
      _localRenderer.srcObject = null;
      try {
        await _localRenderer?.dispose();
      } catch (e) {}
    }

    if (plugin != null) {
      plugin.dispose();
    }
    cleanUpResources();
  }

  cleanUpResources() {
    // remoteRenderers.forEach((key, value) {});
    // remoteRenderers.entries.forEach((element) async {
    //   if (element.value != null) {
    //     try {
    //       element.value.srcObject = null;
    //       remoteRenderers.remove(element.key);
    //     } catch (e) {}
    //     await element.value?.dispose();
    //   }
    // });
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
                  await this.initPlatformState();
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
                  Icons.switch_camera,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (plugin != null) {
                    // plugin.switchCamera();
                  }
                })
          ],
          title: const Text('janus_client'),
        ),
        body: GridView.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: remoteRenderers.entries.toList().length,
            itemBuilder: (context, index) {
              return RTCVideoView(remoteRenderers.entries.toList()[index].value,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: true);
            }));
  }
}
