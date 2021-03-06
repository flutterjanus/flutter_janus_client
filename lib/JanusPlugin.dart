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
  String plugin;
  JanusTransport transport;
  JanusSession session;
  Stream<dynamic> events;
  Stream<dynamic> messages;
  StreamController<dynamic> _streamController;
  StreamController<dynamic> _messagesStreamController;

  Stream<MediaStream> localMediaStream;
  StreamController<MediaStream> _localMediaStreamController;
  int _pollingRetries = 0;
  Timer pollingTimer;
  JanusWebRTCHandle webRTCHandle;

  //temporary variables
  StreamSubscription _wsStreamSubscription;
  bool pollingActive;

  JanusPlugin(
      {this.handleId, this.context, this.transport, this.session, this.plugin});

  handlePolling() async {
    // print('_handleLongPolling');
    if (!pollingActive) return;
    // print('should be called if polling active and request being sent');
    if (session.sessionId == null) {
      pollingActive = false;
      return;
    }
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
        if (!_streamController.isClosed) {
          _streamController.add(element);
        } else {
          pollingActive = false;
          // print('exiting polling');
          return;
        }
      });
      _pollingRetries = 0;
      return;
    } on HttpException catch (e) {
      _pollingRetries++;
      pollingActive = false;
      if (_pollingRetries > 2) {
        // Did we just lose the server? :-(
        print("Lost connection to the server (is it down?)");
        return;
      }
    } catch (e) {
      print(e);
      pollingActive = false;
      print("fatal Exception");
      return;
    }
    return;
  }

  Future<void> hangup() async {
    if (pollingTimer != null) {
      pollingTimer.cancel();
    }

    this.send(data: {"request": "leave"});
    if (webRTCHandle != null) {
      if (webRTCHandle.localStream != null) {
        await webRTCHandle.localStream.dispose();
      }
      if (webRTCHandle.peerConnection != null) {
        await webRTCHandle.peerConnection.close();
      }
    }
    dispose();
  }

  Future<void> init() async {
    if (webRTCHandle != null) {
      return;
    }
    //source and stream for session level events
    _streamController = StreamController<dynamic>();
    events = _streamController.stream.asBroadcastStream();
    //source and stream for localMediaStreams
    _localMediaStreamController = StreamController<MediaStream>();
    localMediaStream = _localMediaStreamController.stream.asBroadcastStream();
    //source and stream for plugin level events
    _messagesStreamController = StreamController<dynamic>();
    messages = _messagesStreamController.stream.asBroadcastStream();

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

    // initializing WebRTC Handle
    Map<String, dynamic> configuration = {
      "iceServers": context.iceServers != null
          ? context.iceServers.map((e) => e.toMap()).toList()
          : []
    };
    configuration.putIfAbsent('sdpSemantics', () => 'plan-b');
    if (context.isUnifiedPlan) {
      configuration.putIfAbsent('sdpSemantics', () => 'unified-plan');
    }

    RTCPeerConnection peerConnection =
        await createPeerConnection(configuration, {});

    // source for onLocalStream
    peerConnection.onAddStream = (mediaStream) {
      _localMediaStreamController.sink.add(mediaStream);
    };
    peerConnection.onRemoveStream = (mediaStream) {
      // _mediaStreamController.sink.add(mediaStream);
    };
    // get ice candidates and send to janus on this plugin handle
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) async {
      Map<String, dynamic> response;
      if (!plugin.contains('textroom')) {
        print('sending trickle');
        Map<String, dynamic> request = {
          "janus": "trickle",
          "candidate": candidate.toMap(),
          "transaction": getUuid().v4()
        };
        request["session_id"] = session.sessionId;
        request["handle_id"] = handleId;
        request["apisecret"] = context.apiSecret;
        request["token"] = context.token;
        //checking and posting using websocket if in available
        if (transport is RestJanusTransport) {
          RestJanusTransport rest = (transport as RestJanusTransport);
          response = await rest.post(request, handleId: handleId);
        } else if (transport is WebSocketJanusTransport) {
          WebSocketJanusTransport ws = (transport as WebSocketJanusTransport);
          response = await ws.send(request, handleId: handleId);
        }
        _streamController.sink.add(response);
      }
    };
    webRTCHandle = JanusWebRTCHandle(peerConnection: peerConnection);
    this.pollingActive = true;
    // Warning no code should be placed after code below in init function
    // depending on transport setup events and messages for session and plugin
    if (transport is RestJanusTransport) {
      pollingTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (!pollingActive) {
          timer.cancel();
        }
        await handlePolling();
      });
    } else if (transport is WebSocketJanusTransport) {
      _wsStreamSubscription =
          (transport as WebSocketJanusTransport).stream.listen((event) {
        _streamController.add(parse(event));
      });
    }
  }

  void dispose() {
    this.pollingActive = false;
    if (pollingTimer != null) {
      pollingTimer.cancel();
    }
    if (_streamController != null) {
      _streamController.close();
    }
    if (_messagesStreamController != null) {
      _messagesStreamController.close();
    }
    if (_localMediaStreamController != null) {
      _localMediaStreamController.close();
    }
    if (_wsStreamSubscription != null) {
      _wsStreamSubscription.cancel();
    }
  }

  Future<dynamic> send({dynamic data, RTCSessionDescription jsep}) async {
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
        print(jsep.toMap());
        request["jsep"] = jsep.toMap();
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
    await webRTCHandle.peerConnection
        .setRemoteDescription(RTCSessionDescription(data["sdp"], data["type"]));
  }

  /// method that generates MediaStream from your device camera that will be automatically added to peer connection instance internally used by janus client
  ///
  /// you can use this method to get the stream and show live preview of your camera to RTCVideoRendererView
  Future<MediaStream> initializeMediaDevices(
      {Map<String, dynamic> mediaConstraints}) async {
    if (mediaConstraints == null) {
      mediaConstraints = {
        "audio": true,
        "video":true
      };

    //   {
    //     "mandatory": {
    // "minWidth":
    // '1280', // Provide your own width, height and frame rate here
    // "minHeight": '720',
    // "minFrameRate": '60',
    // },
    // "facingMode": "user",
    // "optional": [],
    // }
    }
    if (webRTCHandle != null) {
      webRTCHandle.localStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      webRTCHandle.peerConnection.addStream(webRTCHandle.localStream);
      return webRTCHandle.localStream;
    } else {
      print("error webrtchandle cant be null");
      return null;
    }
  }

  /// a utility method which can be used to switch camera of user device if it has more than one camera
  Future<bool> switchCamera() async {
    if (webRTCHandle.localStream != null) {
      final videoTrack = webRTCHandle.localStream
          .getVideoTracks()
          .firstWhere((track) => track.kind == "video");
      return await Helper.switchCamera(videoTrack);
    } else {
      throw "Media devices and stream not initialized,try calling initializeMediaDevices() ";
    }
  }

  Future<RTCSessionDescription> createOffer(
      {bool offerToReceiveAudio = true,
      bool offerToReceiveVideo = true}) async {
    if (context.isUnifiedPlan) {
      await prepareTranscievers(true);
    } else {
      var offerOptions = {
        "offerToReceiveAudio": offerToReceiveAudio,
        "offerToReceiveVideo": offerToReceiveVideo
      };
      // print(offerOptions);
      RTCSessionDescription offer =
          await webRTCHandle.peerConnection.createOffer(offerOptions);
      await webRTCHandle.peerConnection.setLocalDescription(offer);
      return offer;
    }
  }

  Future<RTCSessionDescription> createAnswer({dynamic offerOptions}) async {
    if (context.isUnifiedPlan) {
      print('using transrecievers');
      await prepareTranscievers(false);
    } else {
      try {
        if (offerOptions == null) {
          offerOptions = {
            "offerToReceiveAudio": true,
            "offerToReceiveVideo": true
          };
        }
        RTCSessionDescription offer =
            await webRTCHandle.peerConnection.createAnswer(offerOptions);
        await webRTCHandle.peerConnection.setLocalDescription(offer);
        return offer;
      } catch (e) {
        RTCSessionDescription offer =
            await webRTCHandle.peerConnection.createAnswer(offerOptions);
        await webRTCHandle.peerConnection.setLocalDescription(offer);
      }
    }
//    handling kstable exception most ugly way but currently there's no other workaround, it just works
  }

  Future<void> initDataChannel({RTCDataChannelInit rtcDataChannelInit}) async {
    if (webRTCHandle.peerConnection != null) {
      if (rtcDataChannelInit == null) {
        rtcDataChannelInit = RTCDataChannelInit();
        rtcDataChannelInit.ordered = true;
        rtcDataChannelInit.protocol = 'janus-protocol';
      }
      webRTCHandle.dataChannel[context.dataChannelDefaultLabel] =
          await webRTCHandle.peerConnection.createDataChannel(
              context.dataChannelDefaultLabel, rtcDataChannelInit);
      if (webRTCHandle.dataChannel[context.dataChannelDefaultLabel] != null) {
        webRTCHandle.dataChannel[context.dataChannelDefaultLabel]
            .onDataChannelState = (state) {
          // onDataOpen(state);
        };
        webRTCHandle.dataChannel[context.dataChannelDefaultLabel].onMessage =
            (RTCDataChannelMessage message) {
          // onData(message);
        };
      }
    } else {
      throw Exception(
          "You Must Initialize Peer Connection before even attempting data channel creation!");
    }
  }

  /// Send text message on existing text room using data channel with same label as specified during initDataChannel() method call.
  ///
  /// for now janus text room only supports text as string although with normal data channel api we can send blob or Uint8List if we want.
  Future<void> sendData(String message) async {
    if (message != null) {
      if (webRTCHandle.peerConnection != null) {
        print('before send RTCDataChannelMessage');
        return await webRTCHandle.dataChannel[context.dataChannelDefaultLabel]
            .send(RTCDataChannelMessage(message));
      } else {
        throw Exception(
            "You Must Initialize Peer Connection before even attempting data channel creation or call initDataChannel method!");
      }
    } else {
      throw Exception("message must be provided!");
    }
  }

  Future prepareTranscievers(bool offer) async {
    print('using transrecievers in prepare transrecievers');
    RTCRtpTransceiver audioTransceiver;
    RTCRtpTransceiver videoTransceiver;
    var transceivers = await webRTCHandle.peerConnection.transceivers;
    if (transceivers != null && transceivers.length > 0) {
      transceivers.forEach((t) {
        if ((t.sender != null &&
                t.sender.track != null &&
                t.sender.track.kind == "audio") ||
            (t.receiver != null &&
                t.receiver.track != null &&
                t.receiver.track.kind == "audio")) {
          if (audioTransceiver == null) {
            audioTransceiver = t;
          }
        }
        if ((t.sender != null &&
                t.sender.track != null &&
                t.sender.track.kind == "video") ||
            (t.receiver != null &&
                t.receiver.track != null &&
                t.receiver.track.kind == "video")) {
          if (videoTransceiver == null) {
            videoTransceiver = t;
          }
        }
      });
    }
    if (audioTransceiver != null && audioTransceiver.setDirection != null) {
      audioTransceiver.setDirection(TransceiverDirection.RecvOnly);
    } else {
      audioTransceiver = await webRTCHandle.peerConnection.addTransceiver(
          track: null,
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          init: RTCRtpTransceiverInit(
              direction: offer
                  ? TransceiverDirection.SendOnly
                  : TransceiverDirection.RecvOnly,
              streams: new List()));
    }
    if (videoTransceiver != null && videoTransceiver.setDirection != null) {
      videoTransceiver.setDirection(TransceiverDirection.RecvOnly);
    } else {
      videoTransceiver = await webRTCHandle.peerConnection.addTransceiver(
          track: null,
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init: RTCRtpTransceiverInit(
              direction: offer
                  ? TransceiverDirection.SendOnly
                  : TransceiverDirection.RecvOnly,
              streams: new List()));
    }
  }

  void data() {}
}
