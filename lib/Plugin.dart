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
    return parse((await http.post(_context.currentJanusURI + suffixUrl,
            body: stringify(bod)))
        .body);
  }

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
  Function(dynamic, bool) onLocalTrack;
  Function(dynamic, dynamic, dynamic, bool) onRemoteTrack;
  Function(dynamic) onLocalStream;
  Function(dynamic) onRemoteStream;
  Function(dynamic) onIceConnectionState;
  Function(bool, dynamic) onWebRTCState;
  Function() onDetached;
  Function() onDestroy;
  Function(dynamic, dynamic, dynamic) onMediaState;

  Plugin({
    this.plugin,
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
  });

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
      _webRTCHandle.myStream = await navigator.getUserMedia(mediaConstraints);

      if (_context.isUnifiedPlan) {
        _webRTCHandle.pc
            .addTrack(_webRTCHandle.myStream.getVideoTracks().first);
        _webRTCHandle.pc
            .addTrack(_webRTCHandle.myStream.getAudioTracks().first);
      } else {
        _webRTCHandle.pc.addStream(_webRTCHandle.myStream);
      }

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

  _handleSendResponse(json, Function onsuccess, Function(dynamic) onerror) {
    if (json["janus"] == "success") {
      // We got a success, must have been a synchronous transaction
      var plugindata = json["plugindata"];
      if (plugindata == null) {
        debugPrint(
            "Request succeeded, but missing plugindata...possibly an issue from janus side");
        if (onsuccess != null) {
          onsuccess();
        }
        return;
      }
      debugPrint(
          "Synchronous transaction successful (" + plugindata["plugin"] + ")");

      if (onMessage != null) {
        onMessage(json, null);
      }
      if (onsuccess != null) {
        onsuccess();
      }
      return;
    } else if (json["janus"] == "error") {
      // Not a success and not an ack, must be an error
      if (json["error"] != null) {
        debugPrint("Ooops: " +
            json["error"]["code"].toString() +
            " " +
            json["error"]["reason"]); // FIXME
        if (onerror != null) {
          onerror(
              json["error"]["code"].toString() + " " + json["error"]["reason"]);
        }
      } else {
        debugPrint("Unknown error:" + json.toString()); // FIXME
        if (onerror != null) {
          onerror("Unknown error");
        }
      }
      return;
    }
    // If we got here, the plugin decided to handle the request asynchronously
    if (onsuccess != null) {
      onMessage(json, null);
      onsuccess();
    }
  }

  /// this method exposes communication mechanism to janus server,
  ///
  /// you can send data to janus server in the form of dart map depending on type of plugin used that's why it is dynamic in type
  ///
  /// you can also send jsep (LocalDescription sdp) to janus server if it is required by plugin under use
  ///
  /// onSuccess method is a callback that indicates completion of the request
  send(
      {dynamic message,
      RTCSessionDescription jsep,
      Function onSuccess,
      Function(dynamic) onError}) async {
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

    if (webSocketSink != null && webSocketStream != null) {
      webSocketSink.add(stringify(request));
      _transactions[transaction] = (json) {
        _handleSendResponse(json, onSuccess, onError);
        // _transactions.remove(transaction);
      };
      _webSocketStream.listen((event) {
        if (parse(event)["transaction"] == transaction &&
            parse(event)["janus"] != "ack") {
          print('got event in send method');
          print(event);
          if (_transactions[transaction] != null) {
            _transactions[transaction](parse(event));
          }
        }
      });
    } else {
      var json = await _postRestClient(request, handleId: handleId);
      _handleSendResponse(json, onSuccess, onError);
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

  Future<RTCSessionDescription> createOffer({dynamic offerOptions}) async {
    if (_context.isUnifiedPlan) {
      prepareTranscievers(true);
      //_webRTCHandle.pc.onTrack =
    }
    if (offerOptions == null) {
      offerOptions = {"offerToReceiveAudio": true, "offerToReceiveVideo": true};
    }
    RTCSessionDescription offer =
        await _webRTCHandle.pc.createOffer(offerOptions);
    await _webRTCHandle.pc.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer({dynamic offerOptions}) async {
    if (_context.isUnifiedPlan) {
      prepareTranscievers(false);
    } else {
      if (offerOptions == null) {
        offerOptions = {
          "offerToReceiveAudio": true,
          "offerToReceiveVideo": true
        };
      }
    }
//    handling kstable exception most ugly way but currently there's no other workaround, it just works
    try {
      if (offerOptions == null) offerOptions = new Map();
      RTCSessionDescription offer = await _webRTCHandle.pc.createAnswer({});
      await _webRTCHandle.pc.setLocalDescription(offer);
      return offer;
    } catch (e) {
      RTCSessionDescription offer =
          await _webRTCHandle.pc.createAnswer(offerOptions);
      await _webRTCHandle.pc.setLocalDescription(offer);
      return offer;
    }
  }

  prepareTranscievers(bool offer) async {
    RTCRtpTransceiver audioTransceiver;
    RTCRtpTransceiver videoTransceiver;
    var media = new Map<String, bool>();
    if (!_context.isUnifiedPlan) {
      media = {"offerToReceiveAudio": true, "offerToReceiveVideo": true};
    } else {
      media = prepareMedia(media);

      var transceivers = _webRTCHandle.pc.transceivers;
      var audioSend = isAudioSendEnabled(media);
      var audioRecv = isAudioRecvEnabled(media);
      if (!audioSend && !audioRecv) {
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

      if ((((media["update"] != null && !media["update"]) &&
                  isVideoSendEnabled(media)) ||
              ((media["update"] != null && media["update"]) &&
                  ((media["addVideo"] != null && media["addVideo"]) ||
                      (media["replaceVideo"] != null &&
                          media["replaceVideo"])))) &&
          webRTCHandle.myStream.getVideoTracks() != null &&
          webRTCHandle.myStream.getVideoTracks().length > 0) {
        // webRTCHandle.myStream.addTrack(stream.getVideoTracks()[0]);
        if (_context.isUnifiedPlan) {
          // Use Transceivers
          //  Janus.log((media.replaceVideo ? "Replacing" : "Adding") + " video track:", stream.getVideoTracks()[0]);
          var videoTransceiver = null;
          var transceivers = webRTCHandle.pc.transceivers;
          if (transceivers != null && transceivers.length > 0) {
            for (RTCRtpTransceiver t in transceivers) {
              if ((t.sender != null &&
                      t.sender.track != null &&
                      t.sender.track.kind == "video") ||
                  (t.receiver != null &&
                      t.receiver.track != null &&
                      t.receiver.track.kind == "video")) {
                videoTransceiver = t;
                break;
              }
            }
          }
          if (videoTransceiver != null && videoTransceiver.sender != null) {
            videoTransceiver.sender
                .replaceTrack(webRTCHandle.myStream.getVideoTracks()[0]);
          } else {
            // webRTCHandle.pc.addTrack(webRTCHandle.myStream.getVideoTracks()[0], stream);???
          }
        } else {
          // Janus.log((media.replaceVideo ? "Replacing" : "Adding") + " video track:", stream.getVideoTracks()[0]);
          // webRTCHandle.pc.addTrack(stream.getVideoTracks()[0], stream);
        }
      }
    }
  }

  Map prepareMedia(Map<String, bool> media) {
    if (_webRTCHandle.pc == null) {
      // Nope, new PeerConnection
      media.putIfAbsent("update", () => false);
      media.putIfAbsent("keepAudio", () => false);
      media.putIfAbsent("keepVideo", () => false);
    } else {
      debugPrint("Updating existing media session");
      media["update"] = true;

      //check if we pass a stream and if it is new, otherwise udate the current stream
      // if(callbacks.stream) {
      //   // External stream: is this the same as the one we were using before?
      //   if(callbacks.stream !== config.myStream) {
      //     Janus.log("Renegotiation involves a new external stream");
      //   }
      // } else {
      if (media["addAudio"] != null && media["addAudio"]) {
        media["keepAudio"] = false;
        media["replaceAudio"] = false;
        media["removeAudio"] = false;
        media["audioSend"] = true;

        if (webRTCHandle.myStream != null &&
            webRTCHandle.myStream.getAudioTracks() != null &&
            webRTCHandle.myStream.getAudioTracks().length > 0) {
          debugPrint("Can't add audio stream, there already is one");
          //return error on callback??
          onError("Can't add audio stream, there already is one");
          return null;
        } else if (media["removeAudio"] != null && media["removeAudio"]) {
          media["keepAudio"] = false;
          media["replaceAudio"] = false;
          media["addAudio"] = false;
          media["audioSend"] = false;
        } else if (media["replaceAudio"] != null && media["replaceAudio"]) {
          media["keepAudio"] = false;
          media["addAudio"] = false;
          media["removeAudio"] = false;
          media["audioSend"] = true;
        }
        if (webRTCHandle.myStream == null) {
          if (media["replaceAudio"] != null && media["replaceAudio"]) {
            media["keepAudio"] = false;
            media["replaceAudio"] = false;
            media["addAudio"] = true;
            media["audioSend"] = true;

            if (isAudioSendEnabled(media)) {
              media["keepAudio"] = false;
              media["addAudio"] = true;
            }
          } else {
            if (webRTCHandle.myStream.getAudioTracks() == null ||
                webRTCHandle.myStream.getAudioTracks().length == 0) {
              // No audio track: if we were asked to replace, it's actually an "add"
              if (media["replaceAudio"] != null && media["replaceAudio"]) {
                media["keepAudio"] = false;
                media["replaceAudio"] = false;
                media["addAudio"] = true;
                media["audioSend"] = true;

                if (isAudioSendEnabled(media)) {
                  media["keepAudio"] = false;
                  media["addAudio"] = true;
                }
              } else {
                // We have an audio track: should we keep it as it is?
                if (isAudioSendEnabled(media) &&
                    media["removeAudio"] == false &&
                    media["replaceAudio"] == false) {
                  media["keepAudio"] = true;
                }
              }
            }
            if (media["addVideo"] != null && media["addVideo"]) {
              media["keepVideo"] = false;
              media["replaceVideo"] = false;
              media["removeVideo"] = false;
              media["videoSend"] = true;

              if (webRTCHandle.myStream != null &&
                  webRTCHandle.myStream.getVideoTracks() != null &&
                  webRTCHandle.myStream.getVideoTracks().length > 0) {
                debugPrint("Can't add video stream, there already is one");
                onError("Can't add video stream, there already is one");
                return null;
              }
            } else {}
            if (media["removeVideo"] != null && media["removeVideo"]) {
              media["keepVideo"] = false;
              media["replaceVideo"] = false;
              media["removeVideo"] = false;
              media["videoSend"] = false;
            } else if (media["replaceVideo"] != null && media["replaceVideo"]) {
              media["keepVideo"] = false;
              media["addVideo"] = false;
              media["removeVideo"] = false;
              media["videoSend"] = true;
            }
          }
          if (webRTCHandle.myStream != null) {
            // No media stream: if we were asked to replace, it's actually an "add"

            if (media["replaceVideo"] != null && media["replaceVideo"]) {
              media["keepVideo"] = false;
              media["replaceVideo"] = false;
              media["addVideo"] = true;
              media["videoSend"] = true;
            }

            if (isVideoSendEnabled(media)) {
              media["keepVideo"] = false;
              media["addVideo"] = true;
            }
          } else {
            if (webRTCHandle.myStream.getVideoTracks() != null ||
                webRTCHandle.myStream.getVideoTracks().length == 0) {
              // No video track: if we were asked to replace, it's actually an "add"

              if (media["replaceVideo"] != null && media["replaceVideo"]) {
                media["keepVideo"] = false;
                media["replaceVideo"] = false;
                media["addVideo"] = true;
                media["videoSend"] = true;
              }

              if (isVideoSendEnabled(media)) {
                media["keepVideo"] = false;
                media["addVideo"] = true;
              }
            } else {
              // We have a video track: should we keep it as it is?
              if (isVideoSendEnabled(media) &&
                  media["removeVideo"] != null &&
                  media["replaceVideo"] != null) {
                media["keepVideo"] = true;
              }
            }
          }
          // Data channels can only be added
          if (media["addData"] != null && media["addData"]) {
            media["data"] = true;
          }
        }
      }
    }
    return media;
  }

  // Helper methods to parse a media object
  bool isAudioSendEnabled(Map<String, bool> media) {
    //Janus.debug("isAudioSendEnabled:", media);
    if (media != null) return true; // Default
    if (media["audio"] == false) return false; // Generic audio has precedence
    if (media["audioSend"] == null) return true; // Default
    return (media["audioSend"] = true);
  }

  bool isAudioSendRequired(Map<String, bool> media) {
    // Janus.debug("isAudioSendRequired:", media);
    if (media != null) return false; // Default
    if (media["audio"] == false || media["audioSend"] == false)
      return false; // If we're not asking to capture audio, it's not required
    if (media["failIfNoAudio"] == null) return false; // Default
    return (media["failIfNoAudio"] = true);
  }

  bool isAudioRecvEnabled(Map<String, bool> media) {
    // Janus.debug("isAudioRecvEnabled:", media);
    if (media != null) return true; // Default
    if (media["audio"] == false) return false; // Generic audio has precedence
    if (media["audioRecv"] == null) return true; // Default
    return (media["audioRecv"] = true);
  }

  bool isVideoSendEnabled(Map<String, bool> media) {
    //   Janus.debug("isVideoSendEnabled:", media);
    if (media != null) return true; // Default
    if (media["video"] == false) return false; // Generic video has precedence
    if (media["videoSend"] == null) return true; // Default
    return (media["videoSend"] = true);
  }

  bool isVideoSendRequired(Map<String, bool> media) {
    //Janus.debug("isVideoSendRequired:", media);
    if (media != null) return false; // Default
    if (media["video"] == false || media["videoSend"] == false)
      return false; // If we're not asking to capture video, it's not required
    if (media["failIfNoVideo"] == null) return false; // Default
    return (media["failIfNoVideo"] = true);
  }

  bool isVideoRecvEnabled(Map<String, bool> media) {
    //Janus.debug("isVideoRecvEnabled:", media);
    if (media != null) return true; // Default
    if (media["video"] == false) return false; // Generic video has precedence
    if (media["videoRecv"] == null) return true; // Default
    return (media["videoRecv"] = true);
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
