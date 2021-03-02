import 'dart:async';
import 'package:janus_client/JanusSession.dart';
import 'package:janus_client/JanusTransport.dart';
import 'package:janus_client/janus_client.dart';
import 'package:uuid/uuid.dart';
export 'JanusPlugin.dart';
class JanusClient {
  JanusTransport transport;
  String apiSecret;
  String token;
  bool withCredentials;
  int _pollingRetries = 0;
  int maxEvent;
  Timer _keepAliveTimer;
  List<RTCIceServer> iceServers;
  int refreshInterval;
  bool isUnifiedPlan;
  Uuid _uuid = Uuid();

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

  Future<JanusSession> createSession()async {
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
