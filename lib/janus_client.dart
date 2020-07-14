import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:janus_client/Plugin.dart';
import 'package:janus_client/PluginHandle.dart';
import 'package:janus_client/WebRTCHandle.dart';
import 'package:janus_client/utils.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class JanusClient {
  static const MethodChannel _channel = const MethodChannel('janus_client');
  dynamic server;
  String apiSecret;
  String token;
  bool withCredentials;
  List<RTCIceServer> iceServers;
  int refreshInterval;
  bool _connected = false;
  int _sessionId;
  void Function() _onSuccess;
  void Function(dynamic) _onError;
  Uuid _uuid = Uuid();
  Map<String, dynamic> _transactions = {};
  Map<int, PluginHandle> _pluginHandles = {};
//  WebRTCHandle _webRTCHandle;
//
//  set webRTCHandle(WebRTCHandle value) {
//    _webRTCHandle = value;
//  } //  Timer _retryError;
//
////  Timer _retryComplete;
//  get webRTCHandle => _webRTCHandle;

  dynamic get _apiMap =>
      withCredentials ? apiSecret != null ? {"apisecret": apiSecret} : {} : {};

  dynamic get _tokenMap =>
      withCredentials ? token != null ? {"token": token} : {} : {};
  IOWebSocketChannel _webSocketChannel;
  Stream<dynamic> _webSocketStream;
  WebSocketSink _webSocketSink;

  get isConnected => _connected;

  int get sessionId => _sessionId;

  JanusClient(
      {@required this.server,
      @required this.iceServers,
      this.refreshInterval = 5,
      this.apiSecret,
      this.token,
      this.withCredentials = false});

  Future<dynamic> _attemptWebSocket(String url) async {
    try {
      String transaction = _uuid.v4().replaceAll('-', '');
      _webSocketChannel = IOWebSocketChannel.connect(url,
          protocols: ['janus-protocol'], pingInterval: Duration(seconds: 2));
      _webSocketSink = _webSocketChannel.sink;
      _webSocketStream = _webSocketChannel.stream.asBroadcastStream();

      _webSocketSink.add(stringify({
        "janus": "create",
        "transaction": transaction,
        ..._apiMap,
        ..._tokenMap
      }));

      var data = parse(await _webSocketStream.first);
      if (data["janus"] == "success") {
        _sessionId = data["data"]["id"];
        _connected = true;
//        to keep session alive otherwise session will die after default 60 seconds.
        _keepAlive(refreshInterval: refreshInterval);
        this._onSuccess();
        return data;
      }
    } catch (e) {
      this._connected = false;
      debugPrint(e.toString());
      print(e.toString());
      this._onError(e);
      return Future.value(e);
    }
  }

  _attemptRest(String item) {
//todo:implement all http connect interface
  }

  connect({void Function() onSuccess, void Function(dynamic) onError}) async {
    this._onSuccess = onSuccess;
    this._onError = onError;

    if (server is String) {
      debugPrint('only string');
      if (server.startsWith('ws') || server.startsWith('wss')) {
        debugPrint('trying websocket interface');
        await _attemptWebSocket(server);
      } else {
        debugPrint('trying http/https interface');
        await _attemptRest(server);
      }
    } else if (server is List<String>) {
      debugPrint('only list');
      List<String> tempServer = server;
      for (int i = 0; i < tempServer.length; i++) {
        String item = tempServer[i];
        if (item.startsWith('ws') || item.startsWith('wss')) {
          debugPrint('trying websocket interface');
          await _attemptWebSocket(item);
          if (isConnected) break;
        } else {
          debugPrint('trying http/https interface');
          await _attemptRest(item);
          if (isConnected) break;
        }
      }
    } else {
      debugPrint('invalid server format');
    }
  }

  _keepAlive({int refreshInterval}) {
    //                keep session live dude!
    Timer.periodic(Duration(seconds: refreshInterval), (timer) {
      _webSocketSink.add(stringify({
        "janus": "keepalive",
        "session_id": _sessionId,
        "transaction": _uuid.v4(),
        ..._apiMap,
        ..._tokenMap
      }));
    });
  }

  attach(Plugin plugin) async {
    if (_webSocketSink != null &&
        _webSocketStream != null &&
        _webSocketChannel != null) {
      var opaqueId = plugin.opaqueId;
      var transaction = _uuid.v4();
      Map<String, dynamic> request = {
        "janus": "attach",
        "plugin": plugin.plugin,
        "transaction": transaction
      };
      if (plugin.opaqueId != null) request["opaque_id"] = opaqueId;
      request["token"] = token;
      request["apisecret"] = apiSecret;
      request["session_id"] = sessionId;
      _webSocketSink.add(stringify(request));
      var data = parse(await _webSocketStream.firstWhere(
          (element) => parse(element)["transaction"] == transaction));
      if (data["janus"] != "success") {
//        debugPrint("Ooops: " +
//            data["error"].code +
//            " " +
//            data["error"].reason); // FIXME
        plugin.onError(
            "Ooops: " + data["error"].code + " " + data["error"].reason);
        return;
      }
      print(data);
      int handleId = data["data"]["id"];
      debugPrint("Created handle: " + handleId.toString());

      _webSocketStream.listen((event) {
        _handleEvent(plugin, parse(event));
      });

      Map<String, dynamic> configuration = {
        "iceServers": iceServers.map((e) => e.toMap()).toList()
      };
      print(configuration);
      WebRTCHandle webRTCHandle = WebRTCHandle(
          iceServers: iceServers,
          pc: await createPeerConnection(configuration, {}));

//      calling callback for onIceConnectionState on plugin
      webRTCHandle.pc.onIceConnectionState = (v) {
        if (plugin.onIceConnectionState != null) {
          plugin.onIceConnectionState(v);
        }
      };

      PluginHandle pluginHandle = PluginHandle(
          plugin: plugin.plugin,
          apiSecret: apiSecret,
          token: token,
          sessionId: _sessionId,
          handleId: handleId,
          transactions: _transactions,
          webSocketStream: _webSocketStream,
          webSocketSink: _webSocketSink);
      pluginHandle.webRTCHandle = webRTCHandle;
      _pluginHandles[handleId] = pluginHandle;
      plugin.onSuccess(pluginHandle);

      return;
    }
  }

  _handleEvent(Plugin plugin, Map<String, dynamic> json) {
//      if(!websockets && sessionId !== undefined && sessionId !== null && skipTimeout !== true)
//        eventHandler();
//      if(!websockets && Janus.isArray(json)) {
//        // We got an array: it means we passed a maxev > 1, iterate on all objects
//        for(var i=0; i<json.length; i++) {
//          handleEvent(json[i], true);
//        }
//        return;
//      }
    print('handle event called');
    print(json);

    if (json["janus"] == "keepalive") {
      // Nothing happened
      debugPrint("Got a keepalive on session " + sessionId.toString());
    } else if (json["janus"] == "ack") {
      // Just an ack, we can probably ignore
      debugPrint("Got an ack on session " + sessionId.toString());
      debugPrint(json.toString());
      var transaction = json["transaction"];
      if (transaction != null) {
        var reportSuccess = _transactions[transaction];
        if (reportSuccess != null) reportSuccess(json);
//          delete transactions[transaction];
      }
    } else if (json["janus"] == "success") {
      // Success!
      debugPrint("Got a success on session " + sessionId.toString());
      debugPrint(json.toString());
      var transaction = json["transaction"];
      if (transaction) {
        var reportSuccess = _transactions[transaction];
        if (reportSuccess) reportSuccess(json);
//          delete transactions[transaction];
      }
    } else if (json["janus"] == "trickle") {
      // We got a trickle candidate from Janus
      var sender = json["sender"];

      if (sender == null) {
        debugPrint("WMissing sender...");
        return;
      }
      var pluginHandle = _pluginHandles[sender];
      if (pluginHandle == null) {
        debugPrint("This handle is not attached to this session");
      }
      var candidate = json["candidate"];
      debugPrint("Got a trickled candidate on session " + sessionId.toString());
      debugPrint(candidate.toString());
      var config = pluginHandle.webRTCHandle;
      if (config.pc != null) {
        // Add candidate right now
        debugPrint("Adding remote candidate:" + candidate.toString());
        if (candidate.containsKey("sdpMid") &&
            candidate.containsKey("sdpMLineIndex")) {
          config.pc.addCandidate(RTCIceCandidate(candidate["candidate"],
              candidate["sdpMid"], candidate["sdpMLineIndex"]));
        }
      } else {
        // We didn't do setRemoteDescription (trickle got here before the offer?)
        debugPrint(
            "We didn't do setRemoteDescription (trickle got here before the offer?), caching candidate");
//          if(!config.candidates)
//            config.candidates = [];
//          config.candidates.push(candidate);
//          debugPrint(config.candidates);
      }
    } else if (json["janus"] == "webrtcup") {
      // The PeerConnection with the server is up! Notify this
      debugPrint("Got a webrtcup event on session " + sessionId.toString());
      debugPrint(json.toString());
      var sender = json["sender"];
      if (sender == null) {
        debugPrint("WMissing sender...");
      }
      var pluginHandle = _pluginHandles[sender];
      if (pluginHandle == null) {
        debugPrint("This handle is not attached to this session");
      }
      if (plugin.onWebRTCState != null) {
        plugin.onWebRTCState(true, null);
      }
    } else if (json["janus"] == "hangup") {
      // A plugin asked the core to hangup a PeerConnection on one of our handles
      debugPrint("Got a hangup event on session " + sessionId.toString());
      debugPrint(json.toString());
      var sender = json["sender"];
      if (sender != null) {
        debugPrint("WMissing sender...");
      }
      var pluginHandle = _pluginHandles[sender];
      if (pluginHandle == null) {
        debugPrint("This handle is not attached to this session");
      }
      plugin.onWebRTCState(false, json["reason"]);
      pluginHandle.hangup();
      if (plugin.onDestroy != null) {
        plugin.onDestroy();
      }
    } else if (json["janus"] == "detached") {
      // A plugin asked the core to detach one of our handles
      debugPrint("Got a detached event on session " + sessionId.toString());
      debugPrint(json.toString());
      var sender = json["sender"];
      if (sender == null) {
        debugPrint("WMissing sender...");
      }
      var pluginHandle = _pluginHandles[sender];
      if (pluginHandle == null) {
        // Don't warn here because destroyHandle causes this situation.
      }
      plugin.onDetached();
      pluginHandle.detach();
    } else if (json["janus"] == "media") {
      // Media started/stopped flowing
      debugPrint("Got a media event on session " + sessionId.toString());
      debugPrint(json.toString());
      var sender = json["sender"];
      if (sender == null) {
        debugPrint("WMissing sender...");
      }
      var pluginHandle = _pluginHandles[sender];
      if (pluginHandle == null) {
        debugPrint("This handle is not attached to this session");
      }
      if (plugin.onMediaState != null) {
        plugin.onMediaState(json["type"], json["receiving"]);
      }
    } else if (json["janus"] == "slowlink") {
      debugPrint("Got a slowlink event on session " + sessionId.toString());
      debugPrint(json.toString());
      // Trouble uplink or downlink
      var sender = json["sender"];
      if (sender == null) {
        debugPrint("WMissing sender...");
      }
      var pluginHandle = _pluginHandles[sender];
      if (pluginHandle == null) {
        debugPrint("This handle is not attached to this session");
      }
      pluginHandle.slowLink(json["uplink"], json["lost"]);
    } else if (json["janus"] == "error") {
      // Oops, something wrong happened
      debugPrint("EOoops: " +
          json["error"].code +
          " " +
          json["error"].reason); // FIXME
      var transaction = json["transaction"];
      if (transaction) {
        var reportSuccess = _transactions[transaction];
        if (reportSuccess) {
          reportSuccess(json);
        }
      }
    } else if (json["janus"] == "event") {
      debugPrint("Got a plugin event on session " + sessionId.toString());
      debugPrint(json.toString());
      var sender = json["sender"];
      if (sender != null) {
        debugPrint("WMissing sender...");
      }
      var plugindata = json["plugindata"];
      if (plugindata == null) {
        debugPrint("WMissing plugindata...");
        return;
      }
      debugPrint("  -- Event is coming from " +
          sender.toString() +
          " (" +
          plugindata["plugin"].toString() +
          ")");
      var data = plugindata["data"];
      debugPrint(data.toString());
      var pluginHandle = _pluginHandles[sender];
      if (pluginHandle == null) {
        debugPrint("WThis handle is not attached to this session");
      }
      var jsep = json["jsep"];
      if (jsep != null) {
        debugPrint("Handling SDP as well...");
        debugPrint(jsep.toString());
      }
      var callback = plugin.onMessage;
      if (callback != null) {
        debugPrint("Notifying application...");
        // Send to callback specified when attaching plugin handle
        callback(data, jsep);
      } else {
        // Send to generic callback (?)
        debugPrint("No provided notification callback");
      }
    } else if (json["janus"] == "timeout") {
      debugPrint("ETimeout on session " + sessionId.toString());
      debugPrint(json.toString());
      if (_webSocketChannel != null) {
        _webSocketChannel.sink.close(3504, "Gateway timeout");
      }
    } else {
      debugPrint("WUnknown message/event  '" +
          json["janus"] +
          "' on session " +
          _sessionId.toString());
      debugPrint(json.toString());
    }
  }
}
