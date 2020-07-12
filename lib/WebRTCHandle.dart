import 'package:flutter_webrtc/media_stream.dart';
import 'package:flutter_webrtc/rtc_dtmf_sender.dart';
import 'package:flutter_webrtc/webrtc.dart';

class WebRTCHandle {
  bool started;
  MediaStream myStream;
  bool streamExternal;
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

  WebRTCHandle({
    this.started,
    this.myStream,
    this.streamExternal,
    this.remoteStream,
    this.mySdp,
    this.mediaConstraints,
    this.pc,
    this.dataChannel,
    this.dtmfSender,
    this.trickle,
    this.iceDone,
    this.volume,
    this.bitrate,
  });
}
