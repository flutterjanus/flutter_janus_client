part of janus_client;

abstract class JanusTransport {
  String? url;
  int? sessionId;

  JanusTransport({this.url});

  Future<dynamic> getInfo();

  /// this is called internally whenever [JanusSession] or [JanusPlugin] is disposed for cleaning up of active connections either polling or websocket connection.
  void dispose();
}

///
/// This transport class is provided to [JanusClient] instances in transport property in order to <br>
/// inform the plugin that we need to use Rest as a transport mechanism for communicating with Janus Server.<br>
/// therefore for events sent by Janus server is received with the help of polling.
class RestJanusTransport extends JanusTransport {
  RestJanusTransport({String? url}) : super(url: url);

  /*
  * method for posting data to janus by using http client
  * */
  Future<dynamic> post(body, {int? handleId}) async {
    var suffixUrl = '';
    if (sessionId != null && handleId == null) {
      suffixUrl = suffixUrl + "/$sessionId";
    } else if (sessionId != null && handleId != null) {
      suffixUrl = suffixUrl + "/$sessionId/$handleId";
    }
    try {
      var response = (await http.post(Uri.parse(url! + suffixUrl), body: stringify(body))).body;
      return parse(response);
    } on JsonCyclicError {
      return null;
    } on JsonUnsupportedObjectError {
      return null;
    } catch (e) {
      return null;
    }
  }

  /*
  * private method for get data to janus by using http client
  * */
  Future<dynamic> get({handleId}) async {
    var suffixUrl = '';
    if (sessionId != null && handleId == null) {
      suffixUrl = suffixUrl + "/$sessionId";
    } else if (sessionId != null && handleId != null) {
      suffixUrl = suffixUrl + "/$sessionId/$handleId";
    }
    return parse((await http.get(Uri.parse(url! + suffixUrl))).body);
  }

  @override
  void dispose() {}

  @override
  Future<dynamic> getInfo() async {
    return parse((await http.get(Uri.parse(url! + "/info"))).body);
  }
}

///
/// This transport class is provided to [JanusClient] instances in transport property in order to <br>
/// inform the plugin that we need to use WebSockets as a transport mechanism for communicating with Janus Server.<br>
class WebSocketJanusTransport extends JanusTransport {
  WebSocketJanusTransport({String? url, this.pingInterval}) : super(url: url);
  WebSocketChannel? channel;
  Duration? pingInterval;
  WebSocketSink? sink;
  late Stream stream;
  bool isConnected = false;
  final Map<String, Completer<dynamic>> _pendingTransactions = {};

  void dispose() {
    if (channel != null && sink != null) {
      sink?.close();
      isConnected = false;
    }
  }

  /// this method is used to send json payload to Janus Server for communicating the intent.
  Future<dynamic> send(Map<String, dynamic> data, {int? handleId}) {
    final transaction = data['transaction'];

    if (transaction == null) {
      throw Exception("transaction key missing in body");
    }

    data['session_id'] = sessionId;
    if (handleId != null) {
      data['handle_id'] = handleId;
    }

    final completer = Completer<dynamic>();
    _pendingTransactions[transaction] = completer;

    sink!.add(stringify(data));

    // Optionally add a timeout
    return completer.future.timeout(Duration(seconds: 10), onTimeout: () {
      _pendingTransactions.remove(transaction);
      throw TimeoutException('Timed out waiting for transaction $transaction');
    });
  }

  @override
  Future<dynamic> getInfo() async {
    if (!isConnected) {
      connect();
    }
    Map<String, dynamic> payload = {};
    String transaction = getUuid().v4();
    payload['transaction'] = transaction;
    payload['janus'] = 'info';
    return send(payload);
  }

  /// this method is internally called by plugin to establish connection with provided websocket uri.
  void connect() {
    try {
      isConnected = true;
      channel = WebSocketChannel.connect(Uri.parse(url!), protocols: ['janus-protocol']);
    } catch (e) {
      print(e.toString());
      print('something went wrong');
      isConnected = false;
      dispose();
    }
    sink = channel!.sink;
    stream = channel!.stream.asBroadcastStream();
    stream.listen((event) {
      final msg = parse(event);
      final transaction = msg['transaction'];
      if (transaction != null && _pendingTransactions.containsKey(transaction)) {
        _pendingTransactions[transaction]!.complete(msg);
        _pendingTransactions.remove(transaction);
      }
    });
  }
}
