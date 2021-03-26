import 'dart:async';
import 'package:janus_client/JanusSession.dart';
import 'package:janus_client/JanusTransport.dart';
import 'package:janus_client/janus_client.dart';
export 'shelf.dart';

class JanusClient {
  JanusTransport transport;
  String apiSecret;
  String token;
  bool withCredentials;
  int maxEvent;
  List<RTCIceServer> iceServers = [];
  int refreshInterval;
  bool isUnifiedPlan;

  /*
  * // According to this [Issue](https://github.com/meetecho/janus-gateway/issues/124) we cannot change Data channel Label
  * */
  String get dataChannelDefaultLabel => "JanusDataChannel";

  dynamic get apiMap => withCredentials
      ? apiSecret != null
          ? {"apisecret": apiSecret}
          : {}
      : {};

  dynamic get tokenMap => withCredentials
      ? token != null
          ? {"token": token}
          : {}
      : {};

  JanusClient(
      {this.transport,
      this.iceServers,
      this.refreshInterval = 50,
      this.apiSecret,
      this.isUnifiedPlan = false,
      this.token,
      this.maxEvent = 10,
      this.withCredentials = false});

  Future<JanusSession> createSession() async {
    JanusSession session = JanusSession(
        refreshInterval: refreshInterval, transport: transport, context: this);
    await session.create();
    return session;
  }
}

/*
*
* JanusClient client=JanusClient(
* url:[],
*
* );
*
* JanusSession session=client.createSession()
*
* Plugin plugin=session.attach(Plugins.VideoRoom)
* plugin.send();
* plugin.data();
* plugin.peerConnection.addStream()
* plugin.onMessage
* plugin.onData
* plugin.data
* plugin.message
*
*
*
*
*
* */
