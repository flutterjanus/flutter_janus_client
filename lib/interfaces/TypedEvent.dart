import 'package:flutter_webrtc/flutter_webrtc.dart';

class TypedEvent<T>{
  T event;
  RTCSessionDescription? jsep;

//<editor-fold desc="Data Methods">

  TypedEvent({
    required this.event,
    this.jsep,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || (other is TypedEvent && runtimeType == other.runtimeType && event == other.event && jsep == other.jsep);

  @override
  int get hashCode => event.hashCode ^ jsep.hashCode;

  @override
  String toString() {
    return 'TypedEvent{' + ' event: $event,' + ' jsep: $jsep,' + '}';
  }

  TypedEvent copyWith({
    T? event,
    RTCSessionDescription? jsep,
  }) {
    return TypedEvent(
      event: event ?? this.event,
      jsep: jsep ?? this.jsep,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event': (this.event as dynamic).toMap(),
      'jsep': this.jsep,
    };
  }

  factory TypedEvent.fromMap(Map<String, dynamic> map) {
    return TypedEvent(
      event: map['event'] as T,
      jsep: map['jsep'] as RTCSessionDescription,
    );
  }

//</editor-fold>
}

class JanusEvent {
  JanusEvent({
    this.janus,
    this.sessionId,
    this.transaction,
    this.sender,
    this.plugindata,});

  JanusEvent.fromJson(dynamic json) {
    janus = json['janus'];
    sessionId = json['session_id'];
    transaction = json['transaction'];
    sender = json['sender'];
    plugindata = json['plugindata'] != null ? Plugindata.fromJson(json['plugindata']) : null;
  }
  String? janus;
  int? sessionId;
  String? transaction;
  int? sender;
  Plugindata? plugindata;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['janus'] = janus;
    map['session_id'] = sessionId;
    map['transaction'] = transaction;
    map['sender'] = sender;
    if (plugindata != null) {
      map['plugindata'] = plugindata?.toJson();
    }
    return map;
  }

}

class Plugindata {
  Plugindata({
    this.plugin,
    this.data,});

  Plugindata.fromJson(dynamic json) {
    plugin = json['plugin'];
    data = json['data'] != null ? json['data'] : null;
  }
  String? plugin;
  dynamic data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['plugin'] = plugin;
    if (data != null) {
      map['data'] = data;
    }
    return map;
  }

}