import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/rtc_peerconnection.dart';
import 'package:janus_client/Plugin.dart';
import 'package:janus_client/PluginHandle.dart';
import 'package:janus_client/WebRTCHandle.dart';
import 'package:janus_client/utils.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

class JanusClient {
  static const MethodChannel _channel = const MethodChannel('janus_client');
  dynamic server;
  String apiSecret;
  String token;
  bool withCredentials;
  List<RTCIceServer> iceServers;
  RTCPeerConnection peerConnection;
  bool _connected = false;
  int _sessionId;
  void Function() _onSuccess;
  void Function(dynamic) _onError;
  Uuid _uuid = Uuid();
  Map<String, dynamic> _transactions = {};
  Map<int, PluginHandle> _pluginHandles = {};
  WebRTCHandle _webRTCStuff;

//  Timer _retryError;
//  Timer _retryComplete;

  dynamic get _apiMap =>
      withCredentials ? apiSecret != null ? {"apisecret": apiSecret} : {} : {};

  dynamic get _tokenMap =>
      withCredentials ? token != null ? {"token": token} : {} : {};
  IOWebSocketChannel _webSocketChannel;
  StreamController _websocketStream = StreamController.broadcast();

  get isConnected => _connected;

  int get sessionId => _sessionId;

  JanusClient(
      {@required this.server,
      @required this.iceServers,
      this.apiSecret,
      this.token,
      this.withCredentials = false});

  Future<dynamic> _attemptWebSocket(String url) async {
    try {
      String transaction = _uuid.v4().replaceAll('-', '');
      _webSocketChannel = IOWebSocketChannel.connect(url,
          protocols: ['janus-protocol'], pingInterval: Duration(seconds: 2));
      _webSocketChannel.sink.add(stringify({
        "janus": "create",
        "transaction": transaction,
        ..._apiMap,
        ..._tokenMap
      }));
      _websocketStream.addStream(_webSocketChannel.stream);

//      _websocketStream.stream.listen((event) {}, onError: (e) {
//        Timer.periodic(Duration(seconds: 2), (timer) {
//          _retryComplete = timer;
//          connect(onError: _onError, onSuccess: _onSuccess);
//        });
//      }, onDone: () {
//        Timer.periodic(Duration(seconds: 2), (timer) {
//          _retryComplete = timer;
//          connect(onError: _onError, onSuccess: _onSuccess);
//        });
//      });

      var data = parse(await _websocketStream.stream.first);
      if (data["janus"] == "success") {
        _sessionId = data["data"]["id"];
        _connected = true;
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
//    Map<String, dynamic> configuration = {
//      "iceServers": [
//        {
//          "url": "stun:onemandev.tech:3478",
//          "username": "onemandev",
//          "credential": "SecureIt"
//        },
//        {
//          "url": "turn:onemandev.tech:3478",
//          "username": "onemandev",
//          "credential": "SecureIt"
//        },
//      ]
//    };
//
//    final Map<String, dynamic> offerSdpConstraints = {
//      "mandatory": {
//        "OfferToReceiveAudio": false,
//        "OfferToReceiveVideo": false,
//      },
//      "optional": [],
//    };
//    RTCDataChannelInit rtcDataChannelInit = RTCDataChannelInit();
//    rtcDataChannelInit.id = 1;
//    rtcDataChannelInit.ordered = true;
//    rtcDataChannelInit.maxRetransmitTime = -1;
//    rtcDataChannelInit.maxRetransmits = -1;
//    rtcDataChannelInit.protocol = "sctp";
//    rtcDataChannelInit.negotiated = false;
//    peerConnection =
//        await createPeerConnection(configuration, offerSdpConstraints);
//    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
//      print('onCandidate: ' + candidate.candidate);
//      peerConnection.addCandidate(candidate);
////      setState(() {
////        _sdp += '\n';
////        _sdp += candidate.candidate;
////      });
//    };
//    peerConnection.createDataChannel("datachannel", rtcDataChannelInit);
//    peerConnection.onDataChannel = (datachannel) {
//      datachannel.send(RTCDataChannelMessage());
//    };
//
//    RTCSessionDescription description =
//        await peerConnection.createOffer(offerSdpConstraints);
//    print(description.sdp);
//    peerConnection.setLocalDescription(description);

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

  attach(Plugin plugin) async {
    if (_webSocketChannel != null) {
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
      _webSocketChannel.sink.add(stringify(request));
      var data = parse(await _websocketStream.stream.firstWhere(
          (element) => parse(element)["transaction"] == transaction));
      if (data["janus"] != "success") {
        debugPrint("Ooops: " +
            data["error"].code +
            " " +
            data["error"].reason); // FIXME
        plugin.onError(
            "Ooops: " + data["error"].code + " " + data["error"].reason);
        return;
      }
      print(data);
      int handleId = data["data"]["id"];
      debugPrint("Created handle: " + handleId.toString());
      WebRTCHandle _webRTCStuff = WebRTCHandle();

      PluginHandle pluginHandle = PluginHandle(
          plugin: plugin.plugin,
          apiSecret: apiSecret,
          token: token,
          sessionId: _sessionId,
          handleId: handleId,
          transactions: _transactions,
          webSocketChannel: _webSocketChannel,
          webSocketStream: _websocketStream);
      _pluginHandles[handleId] = pluginHandle;
      plugin.onSuccess(pluginHandle);
      _websocketStream.stream.listen((event) {
        print(parse(event));
      });
      return;
    }
  }
}
