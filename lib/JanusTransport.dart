import 'dart:convert';
import 'dart:io';

import 'package:janus_client/utils.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class JanusTransport {
  String url;
  int sessionId;
  int handleId;
  JanusTransport({this.url});
}

class RestJanusTransport extends JanusTransport {
  RestJanusTransport({String url}) : super(url: url);

  /*
  * method for posting data to janus by using http client
  * */
  Future<dynamic> post(body) async {
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
  Future<dynamic> get() async {
    var suffixUrl = '';
    if (sessionId != null && handleId == null) {
      suffixUrl = suffixUrl + "/$sessionId";
    } else if (sessionId != null && handleId != null) {
      suffixUrl = suffixUrl + "/$sessionId/$handleId";
    }
    return parse((await http.get(Uri.parse(url + suffixUrl))).body);
  }

}

class WebSocketJanusTransport extends JanusTransport {
  WebSocketJanusTransport({String url, this.pingInterval}) : super(url: url);
  WebSocketChannel channel;
  Duration pingInterval;
  WebSocketSink sink;
  Stream stream;
  bool isConnected=false;
  void dispose() {
    sink.close();
  }

  void connect() {
    try {
      isConnected = true;
      channel = IOWebSocketChannel.connect(url,
          protocols: ['janus-protocol'],
          pingInterval:
              pingInterval != null ? pingInterval : Duration(seconds: 2));
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
