import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'package:janus_client/janus_client.dart';

void main() {
  RestJanusTransport rest = RestJanusTransport(url: 'https://master-janus.onemandev.tech/rest');

  WebSocketJanusTransport ws = WebSocketJanusTransport(url: 'wss://master-janus.onemandev.tech/websocket');
  ws.connect();
  group('RestJanusTransport', () {
    test('Create a new Session', () async {
      var response = await rest.post({"janus": "create", "transaction": "sdhbds"});
      rest.sessionId = response['data']['id'];
      expect(response['janus'], 'success');
    });

    test('Attach A Plugin', () async {
      Map<String, dynamic> request = {"janus": "attach", "plugin": "janus.plugin.videoroom", "transaction": "random for attaching plugin"};
      var response = await rest.post(request);

      expect(response['janus'], 'success');
    });
  });

  test('Create a new Session', () async {
    ws.sink!.add({"janus": "create", "transaction": "wscreatesession"});
    ws.stream.listen((event) {
      print(event);
      if (event['transaction'] == 'wscreatesession') {
        rest.sessionId = event['data']['id'];
        print(rest.sessionId);
        stderr.writeln('print me');
        debugPrint(rest.sessionId.toString());
        expect(event['janus'], 'success');
      }
    });
  });
  group('WebSocketJanusTransport', () {
    test('Attach A Plugin', () async {
      Map<String, dynamic> request = {"janus": "attach", "plugin": "janus.plugin.videoroom", "transaction": "random for attaching plugin"};
      ws.sink!.add(request);
      ws.stream.listen((event) {
        if (event['transaction'] == request['transaction']) {
          expect(event['janus'], 'success');
        }
      });
    });
  });
}
