import 'dart:convert';
import 'dart:developer';
import 'dart:math' as Math;
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

class EventMessage{
  dynamic event;
  RTCSessionDescription jsep;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  EventMessage({
    @required this.event,
    @required this.jsep,
  });

  EventMessage copyWith({
    dynamic event,
    RTCSessionDescription jsep,
  }) {
    return new EventMessage(
      event: event ?? this.event,
      jsep: jsep ?? this.jsep,
    );
  }

  @override
  String toString() {
    return 'EventMessage{event: $event, jsep: $jsep}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventMessage &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          jsep == other.jsep);

  @override
  int get hashCode => event.hashCode ^ jsep.hashCode;

  factory EventMessage.fromMap(Map<String, dynamic> map) {
    return new EventMessage(
      event: map['event'] as dynamic,
      jsep: map['jsep'] as RTCSessionDescription,
    );
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'event': this.event,
      'jsep': this.jsep,
    } as Map<String, dynamic>;
  }

//</editor-fold>

}
class RTCIceServer {
  String username;
  String credential;
  String url;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  RTCIceServer({
    @required this.username,
    @required this.credential,
    @required this.url,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RTCIceServer &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          credential == other.credential &&
          url == other.url);

  @override
  int get hashCode => username.hashCode ^ credential.hashCode ^ url.hashCode;

  @override
  String toString() {
    return 'RTCIceServer{' +
        ' username: $username,' +
        ' credential: $credential,' +
        ' url: $url,' +
        '}';
  }

  RTCIceServer copyWith({
    String username,
    String credential,
    String url,
  }) {
    return new RTCIceServer(
      username: username ?? this.username,
      credential: credential ?? this.credential,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': this.username,
      'credential': this.credential,
      'url': this.url,
    };
  }

  factory RTCIceServer.fromMap(Map<String, dynamic> map) {
    return new RTCIceServer(
      username: map['username'] as String,
      credential: map['credential'] as String,
      url: map['url'] as String,
    );
  }

//</editor-fold>
}

class RemoteTrack{
  MediaStream stream;
  MediaStreamTrack track;
  String mid;
  bool flowing;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  RemoteTrack({
    @required this.stream,
    @required this.track,
    @required this.mid,
    @required this.flowing,
  });

  RemoteTrack copyWith({
    MediaStream stream,
    MediaStreamTrack track,
    String mid,
    bool flowing,
  }) {
    return new RemoteTrack(
      stream: stream ?? this.stream,
      track: track ?? this.track,
      mid: mid ?? this.mid,
      flowing: flowing ?? this.flowing,
    );
  }

  @override
  String toString() {
    return 'RemoteTrack{stream: $stream, track: $track, mid: $mid, flowing: $flowing}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteTrack &&
          runtimeType == other.runtimeType &&
          stream == other.stream &&
          track == other.track &&
          mid == other.mid &&
          flowing == other.flowing);

  @override
  int get hashCode =>
      stream.hashCode ^ track.hashCode ^ mid.hashCode ^ flowing.hashCode;

  factory RemoteTrack.fromMap(Map<String, dynamic> map) {
    return new RemoteTrack(
      stream: map['stream'] as MediaStream,
      track: map['track'] as MediaStreamTrack,
      mid: map['mid'] as String,
      flowing: map['flowing'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'stream': this.stream,
      'track': this.track,
      'mid': this.mid,
      'flowing': this.flowing,
    } as Map<String, dynamic>;
  }

//</editor-fold>

}

Uuid getUuid(){
  return Uuid();
}
stringify(dynamic) {
  JsonEncoder encoder = JsonEncoder();
  return '${encoder.convert(dynamic)}';
}

parse(dynamic) {
  JsonDecoder jsonDecoder = JsonDecoder();
  return jsonDecoder.convert(dynamic);
}

randomString({int len=10, String charSet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#\$%^&*()_+'}) {
  var randomString = '';
  for (var i = 0; i < len; i++) {
    var randomPoz = (Math.Random().nextInt(charSet.length-1)).floor();
    randomString += charSet.substring(randomPoz, randomPoz + 1);
  }
  return randomString+Timeline.now.toString();
}
