import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:janus_client/janus_client.dart';

class _MyHttpOverrides extends HttpOverrides {}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MyHttpOverrides();
  WebSocketJanusTransport ws = WebSocketJanusTransport(url: 'wss://janus.conf.meetecho.com/ws');
  RestJanusTransport rest = RestJanusTransport(url: 'https://janus.conf.meetecho.com/janus');
  JanusClient client = JanusClient(transport: ws);
  group('WebSocketJanusTransport', () {
    test('info', () async {
      print((await client.getInfo()).toJson());
    });
  });
  client = JanusClient(transport: rest);
  group('RestJanusTransport', () {
    test('info', () async {
      print(await client.getInfo());
    });
  });
}
