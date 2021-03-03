import 'dart:async';
import 'dart:io';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:janus_client/JanusClient.dart';
import 'package:janus_client/JanusSession.dart';
import 'package:janus_client/JanusTransport.dart';
import 'package:janus_client/utils.dart';

abstract class JanusPlugins {
  static const VIDEO_ROOM = "janus.plugin.videoroom";
  static const AUDIO_BRIDGE = "janus.plugin.audiobridge";
  static const STREAMING = "janus.plugin.streaming";
  static const VIDEO_CALL = "janus.plugin.videocall";
  static const TEXT_ROOM = "janus.plugin.textroom";
  static const ECHO_TEST = "janus.plugin.echotest";
  static const SIP = "janus.plugin.sip";
}

class JanusPlugin {
  int handleId;
  JanusClient context;
  JanusTransport transport;
  JanusSession session;
  Stream<dynamic> events;
  Stream<dynamic> messages;
  StreamController<dynamic> _streamController;
  StreamController<dynamic> _messagesStreamController;
  int _pollingRetries = 0;

  //temporary variables
  StreamSubscription _wsStreamSubscription;

  JanusPlugin({this.handleId, this.context, this.transport, this.session}) {
    _init();
  }

  _handleLongPolling({Duration delay}) async {
    if (session.sessionId == null) return;
    try {
      var longpoll = transport.url +
          "/" +
          session.sessionId.toString() +
          "?rid=" +
          new DateTime.now().millisecondsSinceEpoch.toString();
      if (context.maxEvent != null)
        longpoll = longpoll + "&maxev=" + context.maxEvent.toString();
      if (context.token != null)
        longpoll = longpoll + "&token=" + context.token;
      if (context.apiSecret != null)
        longpoll = longpoll + "&apisecret=" + context.apiSecret;
      List<dynamic> json = parse((await http.get(Uri.parse(longpoll))).body);
      json.forEach((element) {
        _streamController.add(element);
      });
      await Future.delayed(delay)
          .then((value) async => {await _handleLongPolling(delay: delay)});
      _pollingRetries = 0;
    } on HttpException catch (e) {
      _pollingRetries++;
      if (_pollingRetries > 2) {
        // Did we just lose the server? :-(
        print("Lost connection to the server (is it down?)");
        return;
      }
    } catch (e) {
      print(e);
      print("fatal Exception");
      return;
    }
  }

  _init() async {
    _streamController = StreamController<dynamic>();
    _messagesStreamController = StreamController<dynamic>();
    messages=_messagesStreamController.stream.asBroadcastStream();
    events = _streamController.stream.asBroadcastStream();

    //filter and only send events for this handleId
    events.where((event) {
      Map<String, dynamic> result = event;
      if (result.containsKey('sender')) {
        if (result['sender'] as int == handleId) return true;
        return false;
      } else {
        return false;
      }
    }).listen((event) {
     _messagesStreamController.sink.add(event);
    });


    // depending on transport setup events and messages for session and plugin
    if (transport is RestJanusTransport) {
      await _handleLongPolling(delay: Duration(milliseconds: 0));
    } else if (transport is WebSocketJanusTransport) {
      _wsStreamSubscription =
          (transport as WebSocketJanusTransport).stream.listen((event) {
        _streamController.add(parse(event));
      });
    }


  }

  void dispose() {
    if (_streamController != null) {
      _streamController.close();
    }
    if (_messagesStreamController != null) {
      _messagesStreamController.close();
    }
    if (_wsStreamSubscription != null) {
      _wsStreamSubscription.cancel();
    }
  }

  Future<dynamic> send({dynamic data, dynamic jsep}) async {
    try {
      String transaction = getUuid().v4();
      Map<String, dynamic> response;
      var request = {
        "janus": "message",
        "body": data,
        "transaction": transaction,
      };
      if (context.token != null) request["token"] = context.token;
      if (context.apiSecret != null) request["apisecret"] = context.apiSecret;
      if (jsep != null) {
        request["jsep"] = {"type": jsep.type, "sdp": jsep.sdp};
      }
      if (transport is RestJanusTransport) {
        RestJanusTransport rest = (transport as RestJanusTransport);
        response = await rest.post(request, handleId: handleId);
      } else if (transport is WebSocketJanusTransport) {
        WebSocketJanusTransport ws = (transport as WebSocketJanusTransport);
        response = await ws.send(request, handleId: handleId);
      }
      return response;
    } catch (e) {
      print(e);
    }
  }



  /// It allows you to set Remote Description on internal peer connection, Received from janus server
  Future<void> handleRemoteJsep(data) async {
    // await webRTCHandle.pc
    //     .setRemoteDescription(RTCSessionDescription(data["sdp"], data["type"]));
  }

  /// method that generates MediaStream from your device camera that will be automatically added to peer connection instance internally used by janus client
  ///
  /// you can use this method to get the stream and show live preview of your camera to RTCVideoRendererView
  Future<MediaStream> initializeMediaDevices(
      {Map<String, dynamic> mediaConstraints}) async {
    if (mediaConstraints == null) {
      mediaConstraints = {
        "audio": true,
        "video": {
          "mandatory": {
            "minWidth":
            '1280', // Provide your own width, height and frame rate here
            "minHeight": '720',
            "minFrameRate": '60',
          },
          "facingMode": "user",
          "optional": [],
        }
      };
    }
    // if (_webRTCHandle != null) {
    //   _webRTCHandle.myStream =
    //   await navigator.mediaDevices.getUserMedia(mediaConstraints);
    //   _webRTCHandle.pc.addStream(_webRTCHandle.myStream);
    //   return _webRTCHandle.myStream;
    // } else {
    //   print("error webrtchandle cant be null");
    //   return null;
    // }
  }

  /// a utility method which can be used to switch camera of user device if it has more than one camera
  switchCamera() async {
    // if (_webRTCHandle.myStream != null) {
    //   final videoTrack = _webRTCHandle.myStream
    //       .getVideoTracks()
    //       .firstWhere((track) => track.kind == "video");
    //   await videoTrack.switchCamera();
    // } else {
    //   throw "Media devices and stream not initialized,try calling initializeMediaDevices() ";
    // }
  }

  Future<RTCSessionDescription> createOffer(
      {bool offerToReceiveAudio = true,
        bool offerToReceiveVideo = true}) async {
    if (context.isUnifiedPlan) {
      // await prepareTranscievers(true);
    } else {
      var offerOptions = {
        "offerToReceiveAudio": offerToReceiveAudio,
        "offerToReceiveVideo": offerToReceiveVideo
      };
      // print(offerOptions);
      // RTCSessionDescription offer =
      // await _webRTCHandle.pc.createOffer(offerOptions);
      // await _webRTCHandle.pc.setLocalDescription(offer);
      // return offer;
    }
  }

  Future<RTCSessionDescription> createAnswer({dynamic offerOptions}) async {
    if (context.isUnifiedPlan) {
      print('using transrecievers');
      // await prepareTranscievers(false);
    } else {
      try {
        if (offerOptions == null) {
          offerOptions = {
            "offerToReceiveAudio": true,
            "offerToReceiveVideo": true
          };
        }
        // RTCSessionDescription offer =
        // await _webRTCHandle.pc.createAnswer(offerOptions);
        // await _webRTCHandle.pc.setLocalDescription(offer);
        // return offer;
      } catch (e) {
        // RTCSessionDescription offer =
        // await _webRTCHandle.pc.createAnswer(offerOptions);
        // await _webRTCHandle.pc.setLocalDescription(offer);
        // return offer;
      }
    }
//    handling kstable exception most ugly way but currently there's no other workaround, it just works
  }


  Future<void> initDataChannel({RTCDataChannelInit rtcDataChannelInit}) async {
    // if (_webRTCHandle.pc != null) {
    //   if (rtcDataChannelInit == null) {
    //     rtcDataChannelInit = RTCDataChannelInit();
    //     rtcDataChannelInit.ordered = true;
    //     rtcDataChannelInit.protocol = 'janus-protocol';
    //   }
    //   webRTCHandle.dataChannel[_context.dataChannelDefaultLabel] =
    //   await webRTCHandle.pc.createDataChannel(
    //       _context.dataChannelDefaultLabel, rtcDataChannelInit);
    //   if (webRTCHandle.dataChannel[_context.dataChannelDefaultLabel] != null) {
    //     webRTCHandle.dataChannel[_context.dataChannelDefaultLabel]
    //         .onDataChannelState = (state) {
    //       onDataOpen(state);
    //     };
    //     webRTCHandle.dataChannel[_context.dataChannelDefaultLabel].onMessage =
    //         (RTCDataChannelMessage message) {
    //       onData(message);
    //     };
    //   }
    // } else {
    //   throw Exception(
    //       "You Must Initialize Peer Connection before even attempting data channel creation!");
    // }
  }

  /// Send text message on existing text room using data channel with same label as specified during initDataChannel() method call.
  ///
  /// for now janus text room only supports text as string although with normal data channel api we can send blob or Uint8List if we want.
  Future<void> sendData(String message) async {
    // if (message != null) {
    //   if (_webRTCHandle.pc != null) {
    //     print('before send RTCDataChannelMessage');
    //     return await webRTCHandle.dataChannel[_context.dataChannelDefaultLabel]
    //         .send(RTCDataChannelMessage(message));
    //   } else {
    //     throw Exception(
    //         "You Must Initialize Peer Connection before even attempting data channel creation or call initDataChannel method!");
    //   }
    // } else {
    //   throw Exception("message must be provided!");
    // }
  }

  // Future prepareTranscievers(bool offer) async {
  //   print('using transrecievers in prepare transrecievers');
  //   RTCRtpTransceiver audioTransceiver;
  //   RTCRtpTransceiver videoTransceiver;
  //   var transceivers = await _webRTCHandle.pc.transceivers;
  //   if (transceivers != null && transceivers.length > 0) {
  //     transceivers.forEach((t) {
  //       if ((t.sender != null &&
  //           t.sender.track != null &&
  //           t.sender.track.kind == "audio") ||
  //           (t.receiver != null &&
  //               t.receiver.track != null &&
  //               t.receiver.track.kind == "audio")) {
  //         if (audioTransceiver == null) {
  //           audioTransceiver = t;
  //         }
  //       }
  //       if ((t.sender != null &&
  //           t.sender.track != null &&
  //           t.sender.track.kind == "video") ||
  //           (t.receiver != null &&
  //               t.receiver.track != null &&
  //               t.receiver.track.kind == "video")) {
  //         if (videoTransceiver == null) {
  //           videoTransceiver = t;
  //         }
  //       }
  //     });
  //   }
  //   if (audioTransceiver != null && audioTransceiver.setDirection != null) {
  //     audioTransceiver.setDirection(TransceiverDirection.RecvOnly);
  //   } else {
  //     audioTransceiver = await _webRTCHandle.pc.addTransceiver(
  //         track: null,
  //         kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
  //         init: RTCRtpTransceiverInit(
  //             direction: offer
  //                 ? TransceiverDirection.SendOnly
  //                 : TransceiverDirection.RecvOnly,
  //             streams: new List()));
  //   }
  //   if (videoTransceiver != null && videoTransceiver.setDirection != null) {
  //     videoTransceiver.setDirection(TransceiverDirection.RecvOnly);
  //   } else {
  //     videoTransceiver = await _webRTCHandle.pc.addTransceiver(
  //         track: null,
  //         kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
  //         init: RTCRtpTransceiverInit(
  //             direction: offer
  //                 ? TransceiverDirection.SendOnly
  //                 : TransceiverDirection.RecvOnly,
  //             streams: new List()));
  //   }
  // }


  void data() {}
}
