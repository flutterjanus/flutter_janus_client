import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:janus_client/janus_client.dart';

class _MyHttpOverrides extends HttpOverrides {}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MyHttpOverrides();
  WebSocketJanusTransport ws = WebSocketJanusTransport(url: 'wss://janus.conf.meetecho.com/ws');
  JanusClient client = JanusClient(transport: ws);
  JanusSession session = await client.createSession();
  late JanusTextRoomPlugin textRoomPlugin;
  group('WebSocketJanusTransport', () {
    test('Attach A AudioBridgePlugin', () async {
      textRoomPlugin = await session.attach();
    });
    test('list participants', () async {
      print(await textRoomPlugin.listParticipants(1234));
    });
    test('list rooms', () async {
      var data = await textRoomPlugin.listRooms();
      expect(data, isInstanceOf<List<JanusTextRoom>>());
    });
    test('exists', () async {
      print(await textRoomPlugin.exists(1234));
    });
  });
}
