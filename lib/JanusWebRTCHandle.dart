
part of janus_client;

class JanusWebRTCHandle {
  MediaStream? remoteStream;
  MediaStream? localStream;
  RTCPeerConnection? peerConnection;
  Map<String, RTCDataChannel> dataChannel = {};

  JanusWebRTCHandle({
    this.peerConnection,
  });
}
