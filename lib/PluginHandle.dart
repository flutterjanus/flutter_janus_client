import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/rtc_session_description.dart';
import 'package:janus_client/WebRTCHandle.dart';
import 'package:janus_client/utils.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

class PluginHandle {
  int handleId;
  int sessionId;
  String plugin;
  Map<String, dynamic> transactions;
  Map<int, dynamic> pluginHandles;

  PluginHandle(
      {this.handleId,
      this.transactions,
      this.sessionId,
      this.plugin,
      this.token,
      this.apiSecret,
      this.webSocketStream,
      this.webSocketChannel,
      this.pluginHandles,
      this.webRTCStuff});

  Uuid _uuid = Uuid();
  String token;
  String apiSecret;
  StreamController webSocketStream;
  IOWebSocketChannel webSocketChannel;
  WebRTCHandle webRTCStuff;

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
//      if (jsep.e2ee != null) request["jsep"]["e2ee"] = true;
    }
    request["session_id"] = sessionId;
    request["handle_id"] = handleId;
//    debugPrint(request.toString());
    if (webSocketChannel != null) {
      webSocketChannel.sink.add(stringify(request));
      dynamic json = parse(await webSocketStream.stream.firstWhere(
          (element) => parse(element)["transaction"] == transaction));
//      debugPrint("Message sent!");
//      debugPrint(json.toString());
      if (json["janus"] == "success") {
        // We got a success, must have been a synchronous transaction
        var plugindata = json["plugindata"];
        if (plugindata == null) {
          debugPrint("Request succeeded, but missing plugindata...");
          onSuccess();
          return;
        }
        debugPrint("Synchronous transaction successful (" +
            plugindata["plugin"] +
            ")");
        var data = plugindata["data"];
//        debugPrint(data.toString());
        onSuccess(data);
        return;
      } else if (json["janus"] != "ack") {
        // Not a success and not an ack, must be an error
        if (json["error"]) {
          debugPrint("Ooops: " +
              json["error"].code +
              " " +
              json["error"].reason); // FIXME
          onError(json["error"].code + " " + json["error"].reason);
        } else {
          debugPrint("Unknown error"); // FIXME
          onError("Unknown error");
        }
        return;
      }
      // If we got here, the plugin decided to handle the request asynchronously
      onSuccess();
    }

    return;
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
// todo createOffer(callbacks): asks the library to create a WebRTC compliant OFFER;
// todo createAnswer(callbacks): asks the library to create a WebRTC compliant ANSWER;
// todo handleRemoteJsep(callbacks): asks the library to handle an incoming WebRTC compliant session description;
// todo dtmf(parameters): sends a DTMF tone on the PeerConnection;
// todo data(parameters): sends data through the Data Channel, if available;
// todo getBitrate(): gets a verbose description of the currently received stream bitrate;
// todo hangup(sendRequest): tells the library to close the PeerConnection; if the optional sendRequest argument is set to true, then a hangup Janus API request is sent to Janus as well (disabled by default, Janus can usually figure this out via DTLS alerts and the like but it may be useful to enable it sometimes);
// todo detach(parameters):

//  _prepareWebrtc(handleId, {bool isOffer, dynamic jsep, Map<String,
//      dynamic>media, Function(dynamic) onSuccess, Function(dynamic)onError}) {
////  callbacks = callbacks || {};
////  callbacks.success = (typeof callbacks.success == "function") ? callbacks.success : Janus.noop;
////  onError = (typeof onError == "function") ? onError : webrtcError;
//    if (isOffer && jsep) {
//      debugPrint("EProvided a JSEP to a createOffer");
//      onError("Provided a JSEP to a createOffer");
//      return;
//    } else if (!isOffer && jsep == null) {
////    (!jsep || !jsep.type || !jsep.sdp)
//      debugPrint("EA valid JSEP is required for createAnswer");
//      onError("A valid JSEP is required for createAnswer");
//      return;
//    }
//    /* Check that callbacks.media is a (not null) Object */
//    if (media == null) {
//      media = {"audio": true, "video": true};
//    }
//
//    PluginHandle pluginHandle = pluginHandles[handleId];
//    if (pluginHandle == null || pluginHandle.webRTCStuff == null) {
//      debugPrint("wInvalid handle");
//      onError("Invalid handle");
//      return;
//    }
//    WebRTCHandle config = pluginHandle.webRTCStuff;
//    config.trickle = isTrickleEnabled(callbacks.trickle);
//    // Are we updating a session?
//    if (config.pc == null) {
//      // Nope, new PeerConnection
//      media["update"] = false;
//      media["keepAudio"] = false;
//      media["keepVideo"] = false;
//    } else {
//      debugPrint("LUpdating existing media session");
//      media["update"] = true;
//      // Check if there's anything to add/remove/replace, or if we
//      // can go directly to preparing the new SDP offer or answer
//      if (false) {
////        callbacks.stream
//        // External stream: is this the same as the one we were using before?
////        if (callbacks.stream !== config.myStream) {
////          Janus.log("Renegotiation involves a new external stream");
////        }
//      } else {
//        // Check if there are changes on audio
//        if (media["addAudio"]) {
//          media["keepAudio"] = false;
//          media["replaceAudio"] = false;
//          media["removeAudio"] = false;
//          media["audioSend"] = true;
//          if (config.myStream != null &&
//              config.myStream.getAudioTracks() != null &&
//              config.myStream
//                  .getAudioTracks()
//                  .length > 0) {
//            debugPrint("ECan't add audio stream, there already is one");
//            onError("Can't add audio stream, there already is one");
//            return;
//          }
//        } else if (media["removeAudio"]) {
//          media["keepAudio"] = false;
//          media["replaceAudio"] = false;
//          media["addAudio"] = false;
//          media["audioSend"] = false;
//        } else if (media["replaceAudio"]) {
//          media["keepAudio"] = false;
//          media["addAudio"] = false;
//          media["removeAudio"] = false;
//          media["audioSend"] = true;
//        }
//        if (config.myStream == null) {
//          // No media stream: if we were asked to replace, it's actually an "add"
//          if (media["replaceAudio"]) {
//            media["keepAudio"] = false;
//            media["replaceAudio"] = false;
//            media["addAudio"] = true;
//            media["audioSend"] = true;
//          }
//          if (isAudioSendEnabled(media)) {
//            media["keepAudio"] = false;
//            media["addAudio"] = true;
//          }
//        } else {
//          if (config.myStream.getAudioTracks() == null || config.myStream
//              .getAudioTracks()
//              .length == 0) {
//            // No audio track: if we were asked to replace, it's actually an "add"
//            if (media["replaceAudio"]) {
//              media["keepAudio"] = false;
//              media["replaceAudio"] = false;
//              media["addAudio"] = true;
//              media["audioSend"] = true;
//            }
//            if (isAudioSendEnabled(media)) {
//              media["keepAudio"] = false;
//              media["addAudio"] = true;
//            }
//          } else {
//            // We have an audio track: should we keep it as it is?
//            if (isAudioSendEnabled(media) &&
//                !media["removeAudio"] && !media["replaceAudio"]) {
//              media["keepAudio"] = true;
//            }
//          }
//        }
//        // Check if there are changes on video
//        if (media["addVideo"]) {
//          media["keepVideo"] = false;
//          media["replaceVideo"] = false;
//          media["removeVideo"] = false;
//          media["videoSend"] = true;
//          if (config.myStream != null &&
//              config.myStream.getVideoTracks() != null &&
//              config.myStream
//                  .getVideoTracks()
//                  .length > 0) {
//            debugPrint("ECan't add video stream, there already is one");
//            onError("Can't add video stream, there already is one");
//            return;
//          }
//        } else if (media["removeVideo"]) {
//          media["keepVideo"] = false;
//          media["replaceVideo"] = false;
//          media["addVideo"] = false;
//          media["videoSend"] = false;
//        } else if (media["replaceVideo"]) {
//          media["keepVideo"] = false;
//          media["addVideo"] = false;
//          media["removeVideo"] = false;
//          media["videoSend"] = true;
//        }
//        if (config.myStream == null) {
//          // No media stream: if we were asked to replace, it's actually an "add"
//          if (media["replaceVideo"]) {
//            media["keepVideo"] = false;
//            media["replaceVideo"] = false;
//            media["addVideo"] = true;
//            media["videoSend"] = true;
//          }
//          if (isVideoSendEnabled(media)) {
//            media["keepVideo"] = false;
//            media["addVideo"] = true;
//          }
//        } else {
//          if (config.myStream.getVideoTracks() == null || config.myStream
//              .getVideoTracks()
//              .length == 0) {
//            // No video track: if we were asked to replace, it's actually an "add"
//            if (media["replaceVideo"]) {
//              media["keepVideo"] = false;
//              media["replaceVideo"] = false;
//              media["addVideo"] = true;
//              media["videoSend"] = true;
//            }
//            if (isVideoSendEnabled(media)) {
//              media["keepVideo"] = false;
//              media["addVideo"] = true;
//            }
//          } else {
//            // We have a video track: should we keep it as it is?
//            if (isVideoSendEnabled(media) && !media["removeVideo"] &&
//                !media["replaceVideo"]) {
//              media["keepVideo"] = true;
//            }
//          }
//        }
//        // Data channels can only be added
//        if (media["addData"]) {
//          media["data"] = true;
//        }
//      }
//      // If we're updating and keeping all tracks, let's skip the getUserMedia part
//      if ((isAudioSendEnabled(media) && media["keepAudio"]) &&
//          (isVideoSendEnabled(media) && media["keepVideo"])) {
//        streamsDone(handleId, jsep, media, callbacks, config.myStream);
//        return;
//      }
//    }
//    // If we're updating, check if we need to remove/replace one of the tracks
//    if (media["update"] && !config.streamExternal) {
//      if (media["removeAudio"] || media["replaceAudio"]) {
//        if (config.myStream != null &&
//            config.myStream.getAudioTracks() != null &&
//            config.myStream
//                .getAudioTracks()
//                .length > 0) {
//          MediaStreamTrack at = config.myStream.getAudioTracks()[0];
//          debugPrint("LRemoving audio track:" + at.toString());
//          config.myStream.removeTrack(at);
//          try {
////            no idea if that works
//            at.dispose();
//          } catch (e) {}
//        }
////todo unfortunately flutter_webrtc does not support getSenders() so disabling this functionality.
//        //        if (config.pc.getSenders() && config.pc
////            .getSenders()
////            .length) {
////          var ra = true;
////          if (media["replaceAudio"]) {
////            // We can use replaceTrack
////            ra = false;
////          }
////          if (ra) {
////            for (var asnd of config.pc.getSenders()) {
////    if(asnd && asnd.track && asnd.track.kind === "audio") {
////    Janus.log("Removing audio sender:", asnd);
////    config.pc.removeTrack(asnd);
////    }
////    }
////    }
////    }
//    }
//    if(media["removeVideo"] || media["replaceVideo"]) {
//    if(config.myStream!=null && config.myStream.getVideoTracks()!=null && config.myStream.getVideoTracks().length>0) {
//      MediaStreamTrack vt = config.myStream.getVideoTracks()[0];
//    debugPrint("LRemoving video track:"+ vt.toString());
//    config.myStream.removeTrack(vt);
//    try {
//    vt.dispose();
//    } catch(e) {}
//    }
//
////    todo again for same reason getSenders not supported.
////    if(config.pc.getSenders() && config.pc.getSenders().length) {
////    var rv = true;
////    if(media["replaceVideo"]) {
////    // We can use replaceTrack
////    rv = false;
////    }
////    if(rv) {
////    for(var vsnd of config.pc.getSenders()) {
////    if(vsnd && vsnd.track && vsnd.track.kind === "video") {
////    Janus.log("Removing video sender:", vsnd);
////    config.pc.removeTrack(vsnd);
////    }
////    }
////    }
////    }
//
//    }
//    }
//    // Was a MediaStream object passed, or do we need to take care of that?
//    if(callbacks.stream) {
//    var stream = callbacks.stream;
////    Janus.log("MediaStream provided by the application");
////    Janus.debug(stream);
//    // If this is an update, let's check if we need to release the previous stream
//    if(media["update"]) {
//    if(config.myStream!=null && !config.streamExternal) {
//    // We're replacing a stream we captured ourselves with an external one
//    Janus.stopAllTracks(config.myStream);
//    config.myStream = null;
//    }
//    }
//    // Skip the getUserMedia part
//    config.streamExternal = true;
//
//    streamsDone(handleId, jsep, media, callbacks, stream);
//    return;
//    }
//    if(isAudioSendEnabled(media) || isVideoSendEnabled(media)) {
//    if(!Janus.isGetUserMediaAvailable()) {
//    onError("getUserMedia not available");
//    return;
//    }
//    Map<dynamic,dynamic> constraints = { "mandatory": {}, "optional": []};
//
//    var audioSupport = isAudioSendEnabled(media);
//    if(audioSupport && media!=null && media["audio"] is Map)
//    audioSupport = media["audio"];
//    var videoSupport = isVideoSendEnabled(media);
//    if(videoSupport && media!=null) {
//    var simulcast = (callbacks.simulcast == true);
//    var simulcast2 = (callbacks.simulcast2 == true);
//    if((simulcast || simulcast2) && !jsep && !media["video"])
//    media["video"] ="hires";
//    if(media["video"] && media["video"] != 'screen' && media["video"] != 'window') {
//    if(media["video"] is Map) {
//    videoSupport = media["video"];
//    } else {
//    var width = 0;
//    var height = 0, maxHeight = 0;
//    if(media["video"]== 'lowres') {
//    // Small resolution, 4:3
//    height = 240;
//    maxHeight = 240;
//    width = 320;
//    } else if(media["video"]== 'lowres-16:9') {
//    // Small resolution, 16:9
//    height = 180;
//    maxHeight = 180;
//    width = 320;
//    } else if(media["video"]== 'hires' || media["video"]== 'hires-16:9' || media["video"]== 'hdres') {
//    // High(HD) resolution is only 16:9
//    height = 720;
//    maxHeight = 720;
//    width = 1280;
//    } else if(media["video"]== 'fhdres') {
//    // Full HD resolution is only 16:9
//    height = 1080;
//    maxHeight = 1080;
//    width = 1920;
//    } else if(media["video"] == '4kres') {
//    // 4K resolution is only 16:9
//    height = 2160;
//    maxHeight = 2160;
//    width = 3840;
//    } else if(media["video"] == 'stdres') {
//    // Normal resolution, 4:3
//    height = 480;
//    maxHeight = 480;
//    width = 640;
//    } else if(media["video"] == 'stdres-16:9') {
//    // Normal resolution, 16:9
//    height = 360;
//    maxHeight = 360;
//    width = 640;
//    } else {
////    Janus.log("Default video setting is stdres 4:3");
//    height = 480;
//    maxHeight = 480;
//    width = 640;
//    }
////    Janus.log("Adding media constraint:", media["video"]);
//    videoSupport = {
//    'height': {'ideal': height},
//    'width': {'ideal': width}
//    };
////    Janus.log("Adding video constraint:", videoSupport);
//    }
//    } else if(media["video"] == 'screen' || media["video"] == 'window') {
//    if(navigator.getDisplayMedia!=null) {
//    // The new experimental getDisplayMedia API is available, let's use that
//    // https://groups.google.com/forum/#!topic/discuss-webrtc/Uf0SrR4uxzk
//    // https://webrtchacks.com/chrome-screensharing-getdisplaymedia/
//    constraints["video"] = {};
//    if(media["screenshareFrameRate"]) {
//    constraints["video"]["frameRate"] = media["screenshareFrameRate"];
//    }
//    if(media["screenshareHeight"]) {
//    constraints["video"]["height"] = media["screenshareHeight"];
//    }
//    if(media["screenshareWidth"]) {
//    constraints["video"]["width"] = media["screenshareWidth"];
//    }
//    constraints["audio"] = media["captureDesktopAudio"];
//    navigator.getDisplayMedia(constraints)
//        .then((stream) {
//    if(isAudioSendEnabled(media) && !media["keepAudio"]) {
//    navigator.getUserMedia({ "audio": true, "video": false })
//        .then((audioStream) {
//    stream.addTrack(audioStream.getAudioTracks()[0]);
//    streamsDone(handleId, jsep, media, callbacks, stream);
//    });
//    } else {
//    streamsDone(handleId, jsep, media, callbacks, stream);
//    }
//    },onError:(error) {
//    onError(error);
//    });
//    return;
//    }
//    // We're going to try and use the extension for Chrome 34+, the old approach
//    // for older versions of Chrome, or the experimental support in Firefox 33+
//     callbackUserMedia (error, stream) {
//    if(error) {
//    onError(error);
//    } else {
//    streamsDone(handleId, jsep, media, callbacks, stream);
//    }
//    }
//     getScreenMedia(constraints, gsmCallback, useAudio) {
////    Janus.log("Adding media constraint (screen capture)");
//    debugPrint(constraints);
//    navigator.getUserMedia(constraints)
//        .then((stream) {
//    if(useAudio) {
//    navigator.getUserMedia({ "audio": true, "video": false })
//        .then((audioStream) {
//    stream.addTrack(audioStream.getAudioTracks()[0]);
//    gsmCallback(null, stream);
//    });
//    } else {
//    gsmCallback(null, stream);
//    }
//    })
//        .catchError((error) {  gsmCallback(error); });
//    }
//    if(Janus.webRTCAdapter.browserDetails.browser == 'chrome') {
//    var chromever = Janus.webRTCAdapter.browserDetails.version;
//    var maxver = 33;
//    if(window.navigator.userAgent.match('Linux'))
//    maxver = 35; // "known" crash in chrome 34 and 35 on linux
//    if(chromever >= 26 && chromever <= maxver) {
//    // Chrome 26->33 requires some awkward chrome://flags manipulation
//    constraints = {
//    video: {
//    mandatory: {
//    googLeakyBucket: true,
//    maxWidth: window.screen.width,
//    maxHeight: window.screen.height,
//    minFrameRate: media.screenshareFrameRate,
//    maxFrameRate: media.screenshareFrameRate,
//    chromeMediaSource: 'screen'
//    }
//    },
//    audio: isAudioSendEnabled(media) && !media.keepAudio
//    };
//    getScreenMedia(constraints, callbackUserMedia);
//    } else {
//    // Chrome 34+ requires an extension
//    Janus.extension.getScreen(function (error, sourceId) {
//    if (error) {
//
//    return onError(error);
//    }
//    constraints = {
//    audio: false,
//    video: {
//    mandatory: {
//    chromeMediaSource: 'desktop',
//    maxWidth: window.screen.width,
//    maxHeight: window.screen.height,
//    minFrameRate: media.screenshareFrameRate,
//    maxFrameRate: media.screenshareFrameRate,
//    },
//    optional: [
//    {googLeakyBucket: true},
//    {googTemporalLayeredScreencast: true}
//    ]
//    }
//    };
//    constraints.video.mandatory.chromeMediaSourceId = sourceId;
//    getScreenMedia(constraints, callbackUserMedia,
//    isAudioSendEnabled(media) && !media.keepAudio);
//    });
//    }
//    }
//    return;
//    }
//    }
//    // If we got here, we're not screensharing
//    if(media || media["video"] != 'screen') {
//    // Check whether all media sources are actually available or not
////      navigator.getSources()
//    navigator.mediaDevices.enumerateDevices().then((devices) {
//    var audioExist = devices.some((device) {
//    return device.kind == 'audioinput';
//    }),
//    videoExist = isScreenSendEnabled(media) || devices.some((device) {
//    return device.kind == 'videoinput';
//    });
//
//    // Check whether a missing device is really a problem
//    var audioSend = isAudioSendEnabled(media);
//    var videoSend = isVideoSendEnabled(media);
//    var needAudioDevice = isAudioSendRequired(media);
//    var needVideoDevice = isVideoSendRequired(media);
//    if(audioSend || videoSend || needAudioDevice || needVideoDevice) {
//    // We need to send either audio or video
//    var haveAudioDevice = audioSend ? audioExist : false;
//    var haveVideoDevice = videoSend ? videoExist : false;
//    if(!haveAudioDevice && !haveVideoDevice) {
//    // FIXME Should we really give up, or just assume recvonly for both?
////
//    onError('No capture device found');
//    return false;
//    } else if(!haveAudioDevice && needAudioDevice) {
////    /
//    onError('Audio capture is required, but no capture device found');
//    return false;
//    } else if(!haveVideoDevice && needVideoDevice) {
////
//    onError('Video capture is required, but no capture device found');
//    return false;
//    }
//    }
//
//    var gumConstraints = {
//    "audio": (audioExist && !media["keepAudio"]) ? audioSupport : false,
//    "video": (videoExist && !media["keepVideo"]) ? videoSupport : false
//    };
//    debugPrint("LgetUserMedia constraints"+gumConstraints.toString());
//    if (!gumConstraints["audio"] && !gumConstraints["video"]) {
////
//    streamsDone(handleId, jsep, media, callbacks, stream);
//    } else {
//
//    navigator.getUserMedia(gumConstraints)
//        .then((stream) {
////
//    streamsDone(handleId, jsep, media, callbacks, stream);
//    }).catchError((error) {
////
//    onError({"code": error.code, "name": error.name, "message": error.message});
//    });
//    }
//    }).catchError((error) {
////
//    onError(error);
//    });
//    }
//    } else {
//    // No need to do a getUserMedia, create offer/answer right away
//    streamsDone(handleId, jsep, media, callbacks);
//    }
//  }

}
