import 'dart:async';

import 'package:flutter/cupertino.dart';
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
      this.pluginHandles});

  Uuid _uuid = Uuid();
  String token;
  String apiSecret;
  StreamController webSocketStream;
  IOWebSocketChannel webSocketChannel;

  send(
      {dynamic message,
      dynamic jsep,
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
      if (jsep.e2ee) request["jsep"]["e2ee"] = true;
    }
    request["session_id"] = sessionId;
    request["handle_id"] = handleId;
    debugPrint(request.toString());
    if (webSocketChannel != null) {
      webSocketChannel.sink.add(stringify(request));
      dynamic json = parse(await webSocketStream.stream.firstWhere(
          (element) => parse(element)["transaction"] == transaction));
      debugPrint("Message sent!");
      debugPrint(json.toString());
      if (json["janus"] == "success") {
        // We got a success, must have been a synchronous transaction
        var plugindata = json["plugindata"];
        if (!plugindata) {
          debugPrint("Request succeeded, but missing plugindata...");
          onSuccess();
          return;
        }
        debugPrint("Synchronous transaction successful (" +
            plugindata["plugin"] +
            ")");
        var data = plugindata["data"];
        debugPrint(data.toString());
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

}
