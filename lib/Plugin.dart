import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/rtc_session_description.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:janus_client/WebRTCHandle.dart';
import 'package:janus_client/utils.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'WebRTCHandle.dart';

class Plugin {
  String plugin;
  String opaqueId;
  int _handleId;

  int get handleId => _handleId;

  set handleId(int value) {
    _handleId = value;
  }

  int _sessionId;
  Map<String, dynamic> _transactions;
  Map<int, dynamic> _pluginHandles;
  String _token;
  String _apiSecret;
  Stream<dynamic> _webSocketStream;
  WebSocketSink _webSocketSink;
  WebRTCHandle _webRTCHandle;
  Uuid _uuid = Uuid();

  WebRTCHandle get webRTCHandle => _webRTCHandle;

  set webRTCHandle(WebRTCHandle data) {
    _webRTCHandle = data;
  }

  Function(Plugin) onSuccess;
  Function(dynamic) onError;
  Function(dynamic, dynamic) onMessage;
  Function(dynamic) onLocalStream;
  Function(dynamic) onRemoteStream;
  Function(dynamic) onIceConnectionState;
  Function(bool, dynamic) onWebRTCState;
  Function() onDetached;
  Function() onDestroy;
  Function(dynamic, dynamic) onMediaState;

  Plugin({
    this.plugin,
    this.opaqueId,
    this.onSuccess,
    this.onError,
    this.onWebRTCState,
    this.onMessage,
    this.onDestroy,
    this.onDetached,
    this.onLocalStream,
    this.onRemoteStream,
  });

  Future<void> handleRemoteJsep(data) async {
    await webRTCHandle.pc
        .setRemoteDescription(RTCSessionDescription(data["sdp"], data["type"]));
  }

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
      _webRTCHandle.myStream = await navigator.getUserMedia(mediaConstraints);
      _webRTCHandle.pc.addStream(_webRTCHandle.myStream);
      return _webRTCHandle.myStream;
    } else {
      debugPrint("error webrtchandle cant be null");
      return null;
    }
  }

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

  send(
      {dynamic message,
      RTCSessionDescription jsep,
      Function onSuccess,
      Function onError}) async {
    var transaction = _uuid.v4();
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
//    debugPrint(request.toString());
    if (webSocketSink != null && webSocketStream != null) {
      webSocketSink.add(stringify(request));
      dynamic json = parse(await webSocketStream.firstWhere(
          (element) => parse(element)["transaction"] == transaction));
      if (json["janus"] == "success") {
        // We got a success, must have been a synchronous transaction
        var plugindata = json["plugindata"];
        if (plugindata == null) {
          debugPrint("Request succeeded, but missing plugindata...");
          if (onSuccess != null) {
            onSuccess();
          }
          return;
        }
        debugPrint("Synchronous transaction successful (" +
            plugindata["plugin"] +
            ")");
        var data = plugindata["data"];
//        debugPrint(data.toString());
        if (onSuccess != null) {
          onSuccess(data);
        }
        return;
      } else if (json["janus"] != "ack") {
        // Not a success and not an ack, must be an error
        if (json["error"] != null) {
          debugPrint("Ooops: " +
              json["error"].code +
              " " +
              json["error"].reason); // FIXME
          if (onError != null) {
            onError(json["error"].code + " " + json["error"].reason);
          }
        } else {
          debugPrint("Unknown error"); // FIXME
          if (onError != null) {
            onError("Unknown error");
          }
        }
        return;
      }
      // If we got here, the plugin decided to handle the request asynchronously
      if (onSuccess != null) {
        onSuccess();
      }
    }

    return;
  }

  hangup() async {
    this.send(message: {"request": "leave"});
    await _webRTCHandle.myStream.dispose();
    await _webRTCHandle.pc.close();
    _webRTCHandle.pc = null;
  }

  detach() {}

  slowLink(a, b) {}

  Future<RTCSessionDescription> createOffer({dynamic offerOptions}) async {
    if (offerOptions == null) {
      offerOptions = {"offerToReceiveAudio": true, "offerToReceiveVideo": true};
    }
    RTCSessionDescription offer =
        await _webRTCHandle.pc.createOffer(offerOptions);
    _webRTCHandle.pc.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer({dynamic offerOptions}) async {
    if (offerOptions == null) {
      offerOptions = {"offerToReceiveAudio": true, "offerToReceiveVideo": true};
    }

//    handling kstable exception most ugly way but currently there's no other workarround, it just works
    try {
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

  sendData(dynamic text, dynamic data,
      {Function onSuccess, Function(dynamic) onError}) {
    var pluginHandle = pluginHandles[handleId];
    if (pluginHandle == null || !pluginHandle.webrtcStuff) {
      debugPrint("Invalid handle");
      onError("Invalid handle");
      return;
    }
    var config = pluginHandle.webrtcStuff;
    var dat = text || data;
    if (dat == null) {
      debugPrint("Invalid data");
      onError("Invalid data");
      return;
    }

//    var label = callbacks.label ? callbacks.label : Janus.dataChanDefaultLabel;
//    if(!config.dataChannel[label]) {
//      // Create new data channel and wait for it to open
//      createDataChannel(handleId, label, callbacks.protocol, false, data, callbacks.protocol);
//      callbacks.success();
//      return;
//    }
//    if(config.dataChannel[label].readyState !== "open") {
//      config.dataChannel[label].pending.push(data);
//      callbacks.success();
//      return;
//    }
//    Janus.log("Sending data on data channel <" + label + ">");
//    Janus.debug(data);
//    config.dataChannel[label].send(data);
//    callbacks.success();
  }

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

// todo createOffer(callbacks): asks the library to create a WebRTC compliant OFFER;
// todo createAnswer(callbacks): asks the library to create a WebRTC compliant ANSWER;
// todo handleRemoteJsep(callbacks): asks the library to handle an incoming WebRTC compliant session description;
// todo dtmf(parameters): sends a DTMF tone on the PeerConnection;
// todo data(parameters): sends data through the Data Channel, if available;
// todo getBitrate(): gets a verbose description of the currently received stream bitrate;
// todo hangup(sendRequest): tells the library to close the PeerConnection; if the optional sendRequest argument is set to true, then a hangup Janus API request is sent to Janus as well (disabled by default, Janus can usually figure this out via DTLS alerts and the like but it may be useful to enable it sometimes);
// todo detach(parameters):

}
