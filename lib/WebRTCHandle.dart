import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/utils.dart';

class WebRTCHandle {
  MediaStream remoteStream;
  MediaStream localStream;
  // List<RTCIceServer> iceServers;
  RTCPeerConnection peerConnection;
  Map<String, RTCDataChannel> dataChannel = {};

  WebRTCHandle(
      {
        this.remoteStream,
        this.dataChannel,
        this.peerConnection,
      });
}