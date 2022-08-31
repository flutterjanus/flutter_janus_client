part of janus_client;

class RtpForwardStopped {
  RtpForwardStopped({
    this.audiobridge,
    this.room,
    this.streamId,
  });

  RtpForwardStopped.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    streamId = json['stream_id'];
  }
  String? audiobridge;
  dynamic room;
  int? streamId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;
    map['stream_id'] = streamId;
    return map;
  }
}
