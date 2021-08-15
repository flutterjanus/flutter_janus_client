import 'dart:async';
import 'package:janus_client/JanusSession.dart';
import 'package:janus_client/JanusTransport.dart';
import 'package:janus_client/utils.dart';
import 'package:logging/logging.dart';

export 'shelf.dart';

class JanusClient {
  JanusTransport? transport;
  String? apiSecret;
  String? token;
  bool withCredentials;
  int maxEvent;
  List<RTCIceServer>? iceServers = [];
  int refreshInterval;
  bool isUnifiedPlan;
  String loggerName;
  late Logger logger;
  Level loggerLevel;

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
      this.loggerName = "JanusClient",
      this.maxEvent = 10,
      this.loggerLevel = Level.ALL,
      this.withCredentials = false}) {
    logger = Logger.detached(this.loggerName);
    logger.level = this.loggerLevel;
    logger.onRecord.listen((event) {
      print(event);
    });
  }

  Future<JanusSession> createSession() async {
    logger.info("Creating Session");
    logger.fine("fine message");
    JanusSession session = JanusSession(
        refreshInterval: refreshInterval, transport: transport, context: this);
    try {
      await session.create();
    } catch (e) {
      logger.severe(e);
    }
    logger.info("Session Created");
    return session;
  }
}
