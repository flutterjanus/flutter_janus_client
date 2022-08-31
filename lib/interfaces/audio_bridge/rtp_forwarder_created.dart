part of janus_client;

class RtpForwarderCreated {
  RtpForwarderCreated({
    this.audiobridge,
    this.room,
    this.group,
    this.streamId,
    this.host,
    this.port,
  });

  RtpForwarderCreated.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    group = json['group'];
    streamId = json['stream_id'];
    host = json['host'];
    port = json['port'];
  }
  String? audiobridge;
  dynamic room;
  String? group;
  int? streamId;
  String? host;
  int? port;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;
    map['group'] = group;
    map['stream_id'] = streamId;
    map['host'] = host;
    map['port'] = port;
    return map;
  }
}
