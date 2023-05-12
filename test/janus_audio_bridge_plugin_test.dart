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
  late JanusAudioBridgePlugin audioBridgePlugin;
  group('WebSocketJanusTransport', () {
    test('Attach A AudioBridgePlugin', () async {
      audioBridgePlugin = await session.attach<JanusAudioBridgePlugin>();
    });
    test('Test RtpForward', () async {
      print(await audioBridgePlugin.rtpForward("1234", "https://janus.conf.meetecho.com", 9084));
    });
    test('mute a Participant', () async {
      print(await audioBridgePlugin.muteParticipant("1234", 3465765, true));
    });
  });
}
