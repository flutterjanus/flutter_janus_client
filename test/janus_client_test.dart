import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:janus_client/janus_client.dart';

void main() {
  const MethodChannel channel = MethodChannel('janus_client');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await JanusClient.platformVersion, '42');
  });
}
