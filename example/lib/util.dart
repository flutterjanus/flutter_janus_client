import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class StreamRenderer {
  RTCVideoRenderer videoRenderer = RTCVideoRenderer();
  MediaStream? mediaStream;
  String id;
  String? publisherId;
  String? publisherName;
  String? mid;
  bool? isAudioMuted;
  bool? isVideoMuted;

  Future<void> dispose() async {
    await stopAllTracksAndDispose(mediaStream);
    videoRenderer.srcObject = null;
    await videoRenderer.dispose();
  }

  StreamRenderer(this.id);

  Future<void> init() async {
    mediaStream = await createLocalMediaStream('mediaStream_$id');
    isAudioMuted = false;
    isVideoMuted = false;
    await videoRenderer.initialize();
    videoRenderer.srcObject = mediaStream;
  }
}

class VideoRoomPluginStateManager {
  Map<dynamic, StreamRenderer> streamsToBeRendered = {};
  Map<dynamic, dynamic> feedIdToDisplayStreamsMap = {};
  Map<dynamic, dynamic> feedIdToMidSubscriptionMap = {};
  Map<dynamic, dynamic> subStreamsToFeedIdMap = {};
  List<SubscriberUpdateStream> subscribeStreams = [];
  List<SubscriberUpdateStream> unSubscribeStreams = [];

  reset() {
    streamsToBeRendered.clear();
    feedIdToDisplayStreamsMap.clear();
    subStreamsToFeedIdMap.clear();
    feedIdToMidSubscriptionMap.clear();
  }
}

class GenericVideoRoomManagedPlugin {
  JanusVideoRoomPlugin? mediaHandle;
  JanusVideoRoomPlugin? remoteMediaHandle;
  Function? externalSubscribeToMedia;
  Function? externalUnSubscribeStreamMedia;
  JanusSession? session;
  Function onJoinedRoom = (data) {};
  Function onNewParticipants = (data) {};

  dynamic myRoom;
  String? myPin;
  void Function(void Function()) setState = (func) {};
  GenericVideoRoomManagedPlugin({this.myRoom, this.myPin});

  Future<void> unSubscribeStreamMedia(VideoRoomPluginStateManager mediaState, int id, {Map? subscriptionMap}) async {
    var feed = mediaState.feedIdToDisplayStreamsMap[id];
    if (feed == null) return;
    mediaState.feedIdToDisplayStreamsMap.remove(id);
    await mediaState.streamsToBeRendered[id]?.dispose();
    mediaState.streamsToBeRendered.remove(id);
    mediaState.unSubscribeStreams = (feed['streams'] as List<Streams>).map((stream) {
      return SubscriberUpdateStream(feed: id, mid: stream.mid, crossrefid: null);
    }).toList();
    if (remoteMediaHandle != null) await remoteMediaHandle?.update(unsubscribe: mediaState.unSubscribeStreams);
    mediaState.unSubscribeStreams = [];
    if (subscriptionMap != null) {
      subscriptionMap.remove(id);
      return;
    }
    mediaState.feedIdToMidSubscriptionMap.remove(id);
  }

  subscribeToMedia(VideoRoomPluginStateManager mediaState, List<Map<dynamic, dynamic>> sources) async {
    if (sources.length == 0) return;
    var streams = (sources).map((e) => PublisherStream(mid: e['mid'], feed: e['feed'])).toList();
    if (remoteMediaHandle != null) {
      await remoteMediaHandle?.update(subscribe: mediaState.subscribeStreams, unsubscribe: mediaState.unSubscribeStreams);
      mediaState.subscribeStreams = [];
      mediaState.unSubscribeStreams = [];
      return;
    }
    remoteMediaHandle = await this.session?.attach<JanusVideoRoomPlugin>();
    remoteMediaHandle?.renegotiationNeeded?.listen((event) async {
      if (remoteMediaHandle?.webRTCHandle?.peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateHaveRemoteOffer ||
          remoteMediaHandle?.webRTCHandle?.peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer) return;
      print('retrying to connect subscribers');
      await remoteMediaHandle?.start(myRoom, answer: await remoteMediaHandle?.createAnswer(audioRecv: true, audioSend: false, videoRecv: true, videoSend: false));
    });

    await remoteMediaHandle?.joinSubscriber(myRoom, streams: streams, pin: myPin);
    remoteMediaHandle?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      await remoteMediaHandle?.handleRemoteJsep(event.jsep);
      if (data is VideoRoomUpdatedEvent) {
        data.streams?.forEach((element) {
          // to avoid duplicate subscriptions
          if (mediaState.feedIdToMidSubscriptionMap[element.feedId] == null) mediaState.feedIdToMidSubscriptionMap[element.feedId] = {};
          mediaState.feedIdToMidSubscriptionMap[element.feedId][element.mid] = true;
        });
        print('videoroom updated event triggered');

        await remoteMediaHandle?.start(myRoom);
      }
      if (data is VideoRoomAttachedEvent) {
        data.streams?.forEach((element) {
          // to avoid duplicate subscriptions
          if (mediaState.feedIdToMidSubscriptionMap[element.feedId] == null) mediaState.feedIdToMidSubscriptionMap[element.feedId] = {};
          mediaState.feedIdToMidSubscriptionMap[element.feedId][element.mid] = true;
        });
        var answer = await remoteMediaHandle?.createAnswer(audioRecv: true, audioSend: false, videoRecv: true, videoSend: false);
        await remoteMediaHandle?.start(myRoom, answer: answer);
      }
      remoteMediaHandle?.remoteTrack?.listen((event) async {
        String? mid = event.mid;
        int? feedId = mediaState.subStreamsToFeedIdMap[mid];
        print(feedId);
        if (feedId != null) {
          var finalId = feedId.toString();
          if (mediaState.streamsToBeRendered.containsKey(finalId)) {
            if (event.track?.kind == 'audio') {
              setState(() {
                mediaState.streamsToBeRendered.update(finalId, (value) {
                  value.mediaStream?.addTrack(event.track!);
                  value.videoRenderer.muted = false;
                  return value;
                });
              });
            }
          }
          if (event.track?.kind == 'video') {
            StreamRenderer temp = StreamRenderer(finalId);
            await temp.init();
            temp.mediaStream?.addTrack(event.track!);
            temp.videoRenderer.srcObject = temp.mediaStream;
            setState(() {
              mediaState.streamsToBeRendered.putIfAbsent(finalId, () => temp);
            });
          }
        }
      });
    }, onError: (error, trace) {
      print('error');
      print(error.toString());
      if (error is JanusError) {
        print(error.toMap());
      }
    });
    return;
  }

  updateStateWithPublisherMediaInfo(VideoRoomPluginStateManager mediaState, dynamic data, List<dynamic> ownIds) {
    List<Map<dynamic, dynamic>> publisherStreams = [];
    for (Publishers publisher in data.publishers ?? []) {
      if (ownIds.contains(publisher.id)) {
        continue;
      }
      mediaState.feedIdToDisplayStreamsMap[publisher.id!] = {"id": publisher.id, "display": publisher.display, "streams": publisher.streams};
      for (Streams stream in publisher.streams ?? []) {
        if (mediaState.feedIdToMidSubscriptionMap[publisher.id] != null && mediaState.feedIdToMidSubscriptionMap[publisher.id]?[stream.mid] == true) {
          continue;
        }
        publisherStreams.add({"feed": publisher.id, ...stream.toMap()});
        if (publisher.id != null && stream.mid != null) {
          mediaState.subStreamsToFeedIdMap.putIfAbsent(stream.mid, () => publisher.id);
        }
      }
    }
    return publisherStreams;
  }

  init(VideoRoomPluginStateManager mediaState, JanusSession? session, List<dynamic> ownIds, void Function(void Function()) setState) async {
    this.session = session;
    this.setState = setState;
    mediaHandle = await this.session?.attach<JanusVideoRoomPlugin>();
    mediaHandle?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        // print(data.publishers);
        // if (afterJoined != null) {
        //   await afterJoined();
        // } else {
        (await mediaHandle?.configure(bitrate: 3000000, sessionDescription: await mediaHandle?.createOffer(audioRecv: false, audioSend: false, videoSend: true, videoRecv: false)));
        // }
        List<Map<dynamic, dynamic>> publisherStreams = updateStateWithPublisherMediaInfo(mediaState, data, ownIds);
        subscribeToMedia(
          mediaState,
          publisherStreams,
        );
      }
      if (data is VideoRoomNewPublisherEvent) {
        print(data.publishers);
        List<Map<dynamic, dynamic>> publisherStreams = updateStateWithPublisherMediaInfo(mediaState, data, ownIds);
        subscribeToMedia(
          mediaState,
          publisherStreams,
        );
      }
      if (data is VideoRoomLeavingEvent) {
        if (externalUnSubscribeStreamMedia != null) {
          externalUnSubscribeStreamMedia!(mediaState, data.leaving);
          return;
        }
        unSubscribeStreamMedia(
          mediaState,
          data.leaving!,
        );
      }
      await mediaHandle?.handleRemoteJsep(event.jsep);
    }, onError: (error, trace) {
      if (error is JanusError) {
        print(error.toMap());
      }
    });
    mediaHandle?.renegotiationNeeded?.listen((event) async {
      if (mediaHandle?.webRTCHandle?.peerConnection?.signalingState != RTCSignalingState.RTCSignalingStateStable) return;
      print('retrying to connect publisher');
      var offer = await mediaHandle?.createOffer(audioRecv: false, audioSend: true, videoRecv: false, videoSend: true);
      await mediaHandle?.configure(sessionDescription: offer);
    });
  }
}
