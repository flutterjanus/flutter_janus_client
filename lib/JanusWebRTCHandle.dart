import 'package:flutter_webrtc/flutter_webrtc.dart';

class JanusWebRTCHandle {
  MediaStream remoteStream;
  MediaStream localStream;
  RTCPeerConnection peerConnection;
  Map<String, RTCDataChannel> dataChannel = {};

  JanusWebRTCHandle({
    this.peerConnection,
  });
}
