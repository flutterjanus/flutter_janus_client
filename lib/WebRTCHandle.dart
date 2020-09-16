
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/utils.dart';

class WebRTCHandle {
  bool started;
  MediaStream _myStream;

  MediaStream get myStream => _myStream;

  set myStream(MediaStream value) {
    _myStream = value;
  }

  bool streamExternal;
  List<RTCIceServer> iceServers;
  MediaStream remoteStream;
  RTCSessionDescription mySdp;
  dynamic mediaConstraints;
  RTCPeerConnection pc;

  Map<dynamic, RTCDataChannel> dataChannel = {};
  RTCDTMFSender dtmfSender;
  bool trickle;
  bool iceDone;
  Map<dynamic, dynamic> volume;
  Map<dynamic, dynamic> bitrate;

  WebRTCHandle(
      {this.started,
      this.streamExternal,
      this.remoteStream,
      this.mySdp,
      this.mediaConstraints,
      this.dataChannel,
      this.dtmfSender,
      this.trickle,
      this.pc,
      this.iceDone,
      this.volume,
      this.bitrate,
      this.iceServers});
}
