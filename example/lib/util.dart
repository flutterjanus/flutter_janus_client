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
  List<bool> selectedQuality = [false, false, true];
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