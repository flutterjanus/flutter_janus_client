import 'dart:async';

import 'package:janus_client/JanusTransport.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:janus_client/utils.dart';
import 'JanusClient.dart';

class JanusSession {
  int refreshInterval;
  JanusTransport transport;
  JanusClient context;
  int sessionId;
  Map<String, Function> _transactions = {};

  JanusSession({this.refreshInterval, this.transport, this.context});

  Future<void> create() async {
    String transaction = getUuid().v4();
    Map<String, dynamic> request = {
      "janus": "create",
      "transaction": transaction,
      ...context.tokenMap,
      ...context.apiMap
    };
    Map<String, dynamic> response;
    if (transport is RestJanusTransport) {
      RestJanusTransport rest = (transport as RestJanusTransport);
      response = await rest.post(request);
      if (response.containsKey('janus') && response.containsKey('data')) {
        sessionId = response['data']['id'];
        rest.sessionId = sessionId;
      }
    } else if (transport is WebSocketJanusTransport) {
      print('websocket');
      WebSocketJanusTransport ws = (transport as WebSocketJanusTransport);
      // if (!ws.isConnected) {
        ws.connect();
      // }
      ws.sink.add(stringify(request));
      StreamSubscription subscription;
     ws.stream.listen((event) {
       print(event);
        if (event['transaction'] != transaction) {
          if (response.containsKey('janus') && response.containsKey('data')) {
            sessionId = response['data']['id'];
            ws.sessionId = sessionId;
            print(ws.sessionId);
          }
          // subscription.cancel();
        }
      });
    }
  }

  void attach() {}

  _keepAlive({int refreshInterval}) {
    //                keep session live dude!
    print('keep live timer activated');
    // if (isConnected) {
    //   Timer.periodic(Duration(seconds: refreshInterval), (timer) async {
    //     this._keepAliveTimer = timer;
    //     try {
    //       if (_usingRest) {
    //         debugPrint("keep live ping from rest client");
    //         await _postRestClient({
    //           "janus": "keepalive",
    //           "session_id": _sessionId,
    //           "transaction": _uuid.v4(),
    //           ..._apiMap,
    //           ..._tokenMap
    //         });
    //       } else {
    //         debugPrint("keep live ping from websocket client");
    //         _webSocketSink.add(stringify({
    //           "janus": "keepalive",
    //           "session_id": _sessionId,
    //           "transaction": _uuid.v4(),
    //           ..._apiMap,
    //           ..._tokenMap
    //         }));
    //       }
    //     } catch (e) {
    //       print(
    //           'got an exception while sending ping marking connection closed and canceling timer');
    //       this._connected = false;
    //       timer.cancel();
    //     }
    //   });
    // }
  }
}
