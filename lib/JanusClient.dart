part of janus_client;

class JanusClient {
  late JanusTransport _transport;
  String? _apiSecret;
  String? _token;
  late Duration _pollingInterval;
  late bool _withCredentials;
  late int _maxEvent;
  late List<RTCIceServer>? _iceServers = [];
  late int _refreshInterval;
  late bool _isUnifiedPlan;
  late String _loggerName;
  late bool _usePlanB;
  late Logger _logger;
  late Level _loggerLevel;

  /*
  * // According to this [Issue](https://github.com/meetecho/janus-gateway/issues/124) we cannot change Data channel Label
  * */
  String get dataChannelDefaultLabel => "JanusDataChannel";

  dynamic get apiMap => _withCredentials
      ? _apiSecret != null
          ? {"apisecret": _apiSecret}
          : {}
      : {};

  dynamic get tokenMap => _withCredentials
      ? _token != null
          ? {"token": _token}
          : {}
      : {};

  /// JanusClient
  ///
  /// setting usePlanB forces creation of peer connection with plan-b sdb semantics,
  /// and would cause isUnifiedPlan to have no effect on sdpSemantics config
  JanusClient(
      {required JanusTransport transport,
        List<RTCIceServer>? iceServers,
      int refreshInterval = 50,
      String? apiSecret,
      bool isUnifiedPlan = true,
      String? token,
        /// forces creation of peer connection with plan-b sdb semantics
        @Deprecated('set this option to true if you using legacy janus plugins with no unified-plan support only.')
        bool usePlanB=false,
      Duration? pollingInterval,
      loggerName = "JanusClient",
      maxEvent = 10,
      loggerLevel = Level.ALL,
      bool withCredentials = false}) {
      _transport=transport;
      _isUnifiedPlan=isUnifiedPlan;
      _iceServers=iceServers;
      _refreshInterval=refreshInterval;
      _apiSecret=_apiSecret;
      _loggerName=loggerName;
      _maxEvent=maxEvent;
      _loggerLevel=loggerLevel;
      _withCredentials=withCredentials;
      _isUnifiedPlan=isUnifiedPlan;
      _token=token;
      _pollingInterval=pollingInterval??Duration(seconds: 1);
    _usePlanB=usePlanB;
    _logger = Logger.detached(_loggerName);
    _logger.level = _loggerLevel;
    _logger.onRecord.listen((event) {
      print(event);
    });
    this._pollingInterval = pollingInterval ?? Duration(seconds: 1);
  }

  Future<JanusSession> createSession() async {
    _logger.info("Creating Session");
    _logger.fine("fine message");
    JanusSession session = JanusSession(refreshInterval: _refreshInterval, transport: _transport, context: this);
    try {
      await session.create();
    } catch (e) {
      _logger.severe(e);
    }
    _logger.info("Session Created");
    return session;
  }
}
