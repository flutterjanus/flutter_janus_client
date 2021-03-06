import 'dart:convert';
import 'package:janus_client/utils.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class JanusTransport {
  String url;
  int sessionId;

  JanusTransport({this.url});

  void dispose();
}

class RestJanusTransport extends JanusTransport {
  RestJanusTransport({String url}) : super(url: url);

  /*
  * method for posting data to janus by using http client
  * */
  Future<dynamic> post(body, {int handleId}) async {
    var suffixUrl = '';
    if (sessionId != null && handleId == null) {
      suffixUrl = suffixUrl + "/$sessionId";
    } else if (sessionId != null && handleId != null) {
      suffixUrl = suffixUrl + "/$sessionId/$handleId";
    }
    try {
      var response =
          (await http.post(Uri.parse(url + suffixUrl), body: stringify(body)))
              .body;
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
    return parse((await http.get(Uri.parse(url + suffixUrl))).body);
  }

  @override
  void dispose() {}
}

class WebSocketJanusTransport extends JanusTransport {
  WebSocketJanusTransport({String url, this.pingInterval}) : super(url: url);
  WebSocketChannel channel;
  Duration pingInterval;
  WebSocketSink sink;
  Stream stream;
  bool isConnected = false;

  void dispose() {
    if (channel != null && sink != null) {
      sink.close();
    }
  }

  Future<dynamic> send(Map<String, dynamic> data, {int handleId}) async {
    if (data['transaction'] != null) {
      data['session_id'] = sessionId;
      if (handleId != null) {
        data['handle_id'] = handleId;
      }
      sink.add(stringify(data));
      return parse(await stream.firstWhere(
          (element) => (parse(element)['transaction'] == data['transaction'])));
    } else {
      throw "transaction key missing in body";
    }
  }

  void connect() {
    try {
      isConnected = true;
      channel = WebSocketChannel.connect(Uri.parse(url),
          protocols: ['janus-protocol']);
    } catch (e) {
      print(e.toString());
      print('something went wrong');
      isConnected = false;
      dispose();
    }
    sink = channel.sink;
    stream = channel.stream.asBroadcastStream();
  }
}
