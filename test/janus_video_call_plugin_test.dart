import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:janus_client/janus_client.dart';

class _MyHttpOverrides extends HttpOverrides {}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MyHttpOverrides();
  WebSocketJanusTransport ws = WebSocketJanusTransport(url: 'wss://janus.conf.meetecho.com/ws');
  // ws.connect();
  JanusClient client = JanusClient(transport: ws);
  JanusSession session = await client.createSession();
  JanusVideoCallPlugin videoCallPlugin;
  videoCallPlugin = await session.attach<JanusVideoCallPlugin>();
  group('WebSocketJanusTransport', () {
    test('Attach A VideoCallPlugin', () async {
      await videoCallPlugin.getList();
      await videoCallPlugin.register('bcd');
      await videoCallPlugin.call('abc');
      videoCallPlugin.messages?.listen((event) {
        print(event.event);
      });
    });
  });
}
