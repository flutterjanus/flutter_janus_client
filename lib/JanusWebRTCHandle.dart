import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/utils.dart';

class JanusWebRTCHandle {
  MediaStream remoteStream;
  MediaStream localStream;
  RTCPeerConnection peerConnection;
  Map<String, RTCDataChannel> dataChannel = {};

  JanusWebRTCHandle({
    this.peerConnection,
  });
}
