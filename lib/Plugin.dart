import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/WebRTCHandle.dart';
import 'package:janus_client/utils.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'WebRTCHandle.dart';
import 'janus_client.dart';
import 'package:http/http.dart' as http;

/// This Class exposes methods and utility function necessary for directly interacting with plugin.
class Plugin {
  String plugin;
  String opaqueId;
  int _handleId;
  JanusClient _context;

  int get handleId => _handleId;

  set handleId(int value) {
    _handleId = value;
  }

  int _sessionId;
  Map<String, dynamic> _transactions;
  Map<int, Plugin> _pluginHandles;
  String _token;
  String _apiSecret;
  Stream<dynamic> _webSocketStream;
  WebSocketSink _webSocketSink;
  WebRTCHandle _webRTCHandle;
  Uuid _uuid = Uuid();

  int get sessionId => _sessionId;

  set sessionId(int value) {
    _sessionId = value;
  }

  Map<String, dynamic> get transactions => _transactions;

  set transactions(Map<String, dynamic> value) {
    _transactions = value;
  }

  Map<int, dynamic> get pluginHandles => _pluginHandles;

  set pluginHandles(Map<int, dynamic> value) {
    _pluginHandles = value;
  }

  String get token => _token;

  set token(String value) {
    _token = value;
  }

  String get apiSecret => _apiSecret;

  set apiSecret(String value) {
    _apiSecret = value;
  }

  Stream<dynamic> get webSocketStream => _webSocketStream;

  set webSocketStream(Stream<dynamic> value) {
    _webSocketStream = value;
  }

  WebSocketSink get webSocketSink => _webSocketSink;

  set webSocketSink(WebSocketSink value) {
    _webSocketSink = value;
  }

  WebRTCHandle get webRTCHandle => _webRTCHandle;

  set webRTCHandle(WebRTCHandle data) {
    _webRTCHandle = data;
  }

  Function(Plugin) onSuccess;
  Function(dynamic) onError;
  Function(dynamic, dynamic) onMessage;
  Function(dynamic, bool) onLocalTrack;
  Function(dynamic, dynamic, dynamic, bool) onRemoteTrack;
  Function(dynamic) onLocalStream;
  Function(dynamic) onRemoteStream;
  Function(RTCDataChannelState) onDataOpen;
  Function(RTCDataChannelMessage) onData;
  Function(dynamic) onIceConnectionState;
  Function(RTCPeerConnectionState) onWebRTCState;
  Function() onDetached;
  Function() onDestroy;
  Function(dynamic, dynamic, dynamic) onMediaState;

  Plugin(
      {this.plugin,
      this.opaqueId,
      this.onSuccess,
      this.onError,
      this.onWebRTCState,
      this.onMessage,
      this.onDestroy,
      this.onDetached,
      this.onLocalTrack,
      this.onRemoteTrack,
      this.onLocalStream,
      this.onRemoteStream,
      this.onDataOpen,
      this.onData});

  set context(JanusClient val) {
    _context = val;
  }

  Future<dynamic> _postRestClient(bod, {int handleId}) async {
    var suffixUrl = '';
    if (_sessionId != null && handleId == null) {
      suffixUrl = suffixUrl + "/$_sessionId";
    } else if (_sessionId != null && handleId != null) {
      suffixUrl = suffixUrl + "/$_sessionId/$handleId";
    }
    return parse((await http.post(
            Uri.parse(_context.currentJanusURI + suffixUrl),
            body: stringify(bod)))
        .body);
  }

  /// It allows you to set Remote Description on internal peer connection, Received from janus server
  Future<void> handleRemoteJsep(data) async {
    await webRTCHandle.pc
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
    if (_webRTCHandle != null) {
      _webRTCHandle.myStream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _webRTCHandle.pc.addStream(_webRTCHandle.myStream);
      return _webRTCHandle.myStream;
    } else {
      print("error webrtchandle cant be null");
      return null;
    }
  }

  /// a utility method which can be used to switch camera of user device if it has more than one camera
  switchCamera() async {
    if (_webRTCHandle.myStream != null) {
      final videoTrack = _webRTCHandle.myStream
          .getVideoTracks()
          .firstWhere((track) => track.kind == "video");
      await videoTrack.switchCamera();
    } else {
      throw "Media devices and stream not initialized,try calling initializeMediaDevices() ";
    }
  }

  _handleSendResponse(json) {
    print('handleSendResponse');
    print(json);
    if (json["janus"] == "event") {
      var jsep;
      // We got a success, must have been a synchronous transaction
      var plugindata = json["plugindata"];

      if (plugindata['jsep'] != null) {
        jsep = plugindata['jsep'];
      }
      if (plugindata == null) {
        debugPrint(
            "Request succeeded, but missing plugindata...possibly an issue from janus side");

        return;
      }

      if (_pluginHandles[handleId] != null) {
        if (_pluginHandles[handleId].onMessage != null) {
          _pluginHandles[handleId].onMessage(json,jsep);
        }
      }

      // if (onMessage != null) {
      //   onMessage(json, jsep);
      // }

      return;
    } else if (json["janus"] == "error") {
      // Not a success and not an ack, must be an error
      if (json["error"] != null) {
        debugPrint("Ooops: " +
            json["error"]["code"].toString() +
            " " +
            json["error"]["reason"]); // FIXME

      } else {
        debugPrint("Unknown error:" + json.toString()); // FIXME

      }
      return;
    }
    // If we got here, the plugin decided to handle the request asynchronously
  }

  /// this method exposes communication mechanism to janus server,
  ///
  /// you can send data to janus server in the form of dart map depending on type of plugin used that's why it is dynamic in type
  ///
  /// you can also send jsep (LocalDescription sdp) to janus server if it is required by plugin under use
  ///
  /// onSuccess method is a callback that indicates completion of the request
  Future<void> send({dynamic message, RTCSessionDescription jsep}) async {
    var transaction = _uuid.v4() + _uuid.v1() + _uuid.v4();
    var request = {
      "janus": "message",
      "body": message,
      "transaction": transaction
    };
    if (token != null) request["token"] = token;
    if (apiSecret != null) request["apisecret"] = apiSecret;
    if (jsep != null) {
      request["jsep"] = {"type": jsep.type, "sdp": jsep.sdp};
    }
    request["session_id"] = sessionId;
    request["handle_id"] = handleId;

    if (webSocketSink != null && webSocketStream != null) {
      webSocketSink.add(stringify(request));
      _transactions[transaction] = (json) {
        _handleSendResponse(json);
        // _transactions.remove(transaction);
      };
      // _webSocketStream.listen((event) {
      //   if (_transactions.containsKey(parse(event)["transaction"]) &&
      //       parse(event)["janus"] != "ack") {
      //     print('got event in send method');
      //       _transactions[parse(event)["transaction"]](parse(event));
      //     _transactions.remove(parse(event)["transaction"]);
      //   }
      // });
      // subscription.cancel();
    } else {
      var json = await _postRestClient(request, handleId: handleId);
      _handleSendResponse(json);
    }

    return;
  }

  /// ends videocall,leaves videoroom and leaves audio room
  hangup() async {
    this.send(message: {"request": "leave"});
    await _webRTCHandle.myStream.dispose();
    await _webRTCHandle.pc.close();
    _context.destroy();
    _webRTCHandle.pc = null;
  }

  /// Cleans Up everything related to individual plugin handle
  Future<void> destroy() async {
    if (_webRTCHandle != null && _webRTCHandle.myStream != null) {
      await _webRTCHandle.myStream.dispose();
    }

    if (_webRTCHandle.pc != null) {
      await _webRTCHandle.pc.dispose();
    }

    if (_webSocketSink != null) {
      await webSocketSink.close();
    }
    _pluginHandles.remove(handleId);
    _handleId = null;
  }

  slowLink(a, b, c) {}

  Future<RTCSessionDescription> createOffer(
      {bool offerToReceiveAudio = true,
      bool offerToReceiveVideo = true}) async {
    if (_context.isUnifiedPlan) {
      await prepareTranscievers(true);
    } else {
      var offerOptions = {
        "offerToReceiveAudio": offerToReceiveAudio,
        "offerToReceiveVideo": offerToReceiveVideo
      };
      print(offerOptions);
      RTCSessionDescription offer =
          await _webRTCHandle.pc.createOffer(offerOptions);
      await _webRTCHandle.pc.setLocalDescription(offer);
      return offer;
    }
  }

  Future<RTCSessionDescription> createAnswer({dynamic offerOptions}) async {
    if (_context.isUnifiedPlan) {
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
            await _webRTCHandle.pc.createAnswer(offerOptions);
        await _webRTCHandle.pc.setLocalDescription(offer);
        return offer;
      } catch (e) {
        RTCSessionDescription offer =
            await _webRTCHandle.pc.createAnswer(offerOptions);
        await _webRTCHandle.pc.setLocalDescription(offer);
        return offer;
      }
    }
//    handling kstable exception most ugly way but currently there's no other workaround, it just works
  }

  Future prepareTranscievers(bool offer) async {
    print('using transrecievers in prepare transrecievers');
    RTCRtpTransceiver audioTransceiver;
    RTCRtpTransceiver videoTransceiver;
    var transceivers = await _webRTCHandle.pc.transceivers;
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
      audioTransceiver = await _webRTCHandle.pc.addTransceiver(
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
      videoTransceiver = await _webRTCHandle.pc.addTransceiver(
          track: null,
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init: RTCRtpTransceiverInit(
              direction: offer
                  ? TransceiverDirection.SendOnly
                  : TransceiverDirection.RecvOnly,
              streams: new List()));
    }
  }

  Future<void> initDataChannel({RTCDataChannelInit rtcDataChannelInit}) async {
    if (_webRTCHandle.pc != null) {
      if (rtcDataChannelInit == null) {
        rtcDataChannelInit = RTCDataChannelInit();
        rtcDataChannelInit.ordered = true;
        rtcDataChannelInit.protocol = 'janus-protocol';
      }
      webRTCHandle.dataChannel[_context.dataChannelDefaultLabel] =
          await webRTCHandle.pc.createDataChannel(
              _context.dataChannelDefaultLabel, rtcDataChannelInit);
      if (webRTCHandle.dataChannel[_context.dataChannelDefaultLabel] != null) {
        webRTCHandle.dataChannel[_context.dataChannelDefaultLabel]
            .onDataChannelState = (state) {
          onDataOpen(state);
        };
        webRTCHandle.dataChannel[_context.dataChannelDefaultLabel].onMessage =
            (RTCDataChannelMessage message) {
          onData(message);
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
  Future<void> sendData({@required String message}) async {
    if (message != null) {
      if (_webRTCHandle.pc != null) {
        print('before send RTCDataChannelMessage');
        return await webRTCHandle.dataChannel[_context.dataChannelDefaultLabel]
            .send(RTCDataChannelMessage(message));
      } else {
        throw Exception(
            "You Must Initialize Peer Connection before even attempting data channel creation or call initDataChannel method!");
      }
    } else {
      throw Exception("message must be provided!");
    }
  }

// todo dtmf(parameters): sends a DTMF tone on the PeerConnection;
// todo data(parameters): sends data through the Data Channel, if available;
// todo getBitrate(): gets a verbose description of the currently received stream bitrate;
// todo detach(parameters):

}
