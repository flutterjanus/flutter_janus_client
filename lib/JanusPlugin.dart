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
  Stream<EventMessage> messages;
  Stream<RemoteTrack> remoteTrack;
  Stream<MediaStream> remoteStream;
  Stream<MediaStream> localStream;
  StreamController<MediaStream> _localStreamController;
  StreamController<RemoteTrack> _remoteTrackStreamController;
  StreamController<MediaStream> _remoteStreamController;
  StreamController<dynamic> _streamController;
  StreamController<EventMessage> _messagesStreamController;

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
    } on HttpException catch (_) {
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
    //source and stream for localStream
    _localStreamController = StreamController<MediaStream>();
    localStream = _localStreamController.stream.asBroadcastStream();
    //source and stream for plugin level events
    _messagesStreamController = StreamController<EventMessage>();
    messages = _messagesStreamController.stream.asBroadcastStream();

    // remote track for unified plan support
    _remoteTrackStreamController = StreamController<RemoteTrack>();
    remoteTrack = _remoteTrackStreamController.stream.asBroadcastStream();
    // remote MediaStream plan-b
    _remoteStreamController = StreamController<MediaStream>();
    remoteStream = _remoteStreamController.stream.asBroadcastStream();

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
      var jsep = event['jsep'];
      if (jsep != null) {
        _messagesStreamController.sink.add(EventMessage(
            event: event,
            jsep: RTCSessionDescription(jsep['sdp'], jsep['type'])));
      } else {
        _messagesStreamController.sink
            .add(EventMessage(event: event, jsep: null));
      }
    });

    // initializing WebRTC Handle
    Map<String, dynamic> configuration = {
      "iceServers": context.iceServers != null
          ? context.iceServers.map((e) => e.toMap()).toList()
          : []
    };
    if (context.isUnifiedPlan) {
      configuration.putIfAbsent('sdpSemantics', () => 'unified-plan');
    } else {
      configuration.putIfAbsent('sdpSemantics', () => 'plan-b');
    }
    print('peer connection configuration');
    print(configuration);
    RTCPeerConnection peerConnection =
        await createPeerConnection(configuration, {});
    if (context.isUnifiedPlan) {
      peerConnection.onTrack = (RTCTrackEvent event) async {
        if (event.streams == null || event.transceiver == null) return;
        var mid =
            event.transceiver != null ? event.transceiver.mid : event.track.id;

        _remoteTrackStreamController.add(RemoteTrack(
            stream: event.streams.where((element) => element != null).first,
            track: event.track,
            mid: mid,
            flowing: true));
        if (event.track != null) {
          // if (event.track != null && event.track.onEnded == null) return;
          event.track.onEnded = () async {
            if (webRTCHandle.remoteStream != null) {
              webRTCHandle.remoteStream.removeTrack(event.track);
              var mid = event.track.id;
              var transceiver = (await peerConnection.transceivers).firstWhere(
                  (element) => element.receiver.track == event.track);
              mid = transceiver.mid;
              _remoteTrackStreamController.add(RemoteTrack(
                  stream:
                      event.streams.where((element) => element != null).first,
                  track: event.track,
                  mid: mid,
                  flowing: false));
            }
          };

          event.track.onMute = () async {
            if (webRTCHandle.remoteStream != null) {
              webRTCHandle.remoteStream.removeTrack(event.track);
              var mid = event.track.id;
              var transceiver = (await peerConnection.transceivers).firstWhere(
                  (element) => element.receiver.track == event.track);
              mid = transceiver.mid;
              _remoteTrackStreamController.add(RemoteTrack(
                  stream:
                      event.streams.where((element) => element != null).first,
                  track: event.track,
                  mid: mid,
                  flowing: false));
            }
          };
        }
      };
    }

    // source for onRemoteStream
    peerConnection.onAddStream = (mediaStream) {
      _remoteStreamController.sink.add(mediaStream);
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
    if (_remoteStreamController != null) {
      _remoteStreamController.close();
    }
    if (_messagesStreamController != null) {
      _messagesStreamController.close();
    }
    if (_localStreamController != null) {
      _localStreamController.close();
    }
    if (_remoteTrackStreamController != null) {
      _remoteTrackStreamController.close();
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
  Future<void> handleRemoteJsep(RTCSessionDescription data) async {
    await webRTCHandle.peerConnection.setRemoteDescription(data);
  }

  /// method that generates MediaStream from your device camera that will be automatically added to peer connection instance internally used by janus client
  ///
  /// you can use this method to get the stream and show live preview of your camera to RTCVideoRendererView
  Future<MediaStream> initializeMediaDevices(
      {Map<String, dynamic> mediaConstraints}) async {
    if (mediaConstraints == null) {
      List<MediaDeviceInfo> audioDevices = await Helper.audiooutputs;
      List<MediaDeviceInfo> videoDevices = await Helper.cameras;
      mediaConstraints = {
        "audio": audioDevices.length > 0,
        "video": videoDevices.length > 0
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
      if (context.isUnifiedPlan) {
        webRTCHandle.localStream.getTracks().forEach((element) {
          webRTCHandle.peerConnection
              .addTrack(element, webRTCHandle.localStream);
        });
      } else {
        _localStreamController.sink.add(webRTCHandle.localStream);
        await webRTCHandle.peerConnection.addStream(webRTCHandle.localStream);
      }
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
    }
    var offerOptions = {
      "offerToReceiveAudio": offerToReceiveAudio,
      "offerToReceiveVideo": offerToReceiveVideo
    };
    RTCSessionDescription offer =
        await webRTCHandle.peerConnection.createOffer(offerOptions);
    await webRTCHandle.peerConnection.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer(
      {bool offerToReceiveAudio = true,
      bool offerToReceiveVideo = true}) async {
    if (context.isUnifiedPlan) {
      print('using transrecievers');
      await prepareTranscievers(false);
    }
    var offerOptions = {
      "offerToReceiveAudio": offerToReceiveAudio,
      "offerToReceiveVideo": offerToReceiveVideo
    };
    try {
      RTCSessionDescription offer =
          await webRTCHandle.peerConnection.createAnswer(offerOptions);
      await webRTCHandle.peerConnection.setLocalDescription(offer);
      return offer;
    } catch (e) {
      //    handling kstable exception most ugly way but currently there's no other workaround, it just works
      RTCSessionDescription offer =
          await webRTCHandle.peerConnection.createAnswer(offerOptions);
      await webRTCHandle.peerConnection.setLocalDescription(offer);
      return offer;
    }
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
    print(transceivers);
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
      await audioTransceiver.setDirection(TransceiverDirection.RecvOnly);
    } else {
      audioTransceiver = await webRTCHandle.peerConnection.addTransceiver(
          track: null,
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          init: RTCRtpTransceiverInit(
              direction: offer
                  ? TransceiverDirection.SendOnly
                  : TransceiverDirection.RecvOnly,
              streams: []));
    }
    if (videoTransceiver != null && videoTransceiver.setDirection != null) {
      await videoTransceiver.setDirection(TransceiverDirection.RecvOnly);
    } else {
      videoTransceiver = await webRTCHandle.peerConnection.addTransceiver(
          track: null,
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init: RTCRtpTransceiverInit(
              direction: offer
                  ? TransceiverDirection.SendOnly
                  : TransceiverDirection.RecvOnly,
              streams: []));
    }
  }

  void data() {}
}
