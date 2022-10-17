part of janus_client;

class AudioRoomCreatedResponse {
  AudioRoomCreatedResponse({
    this.audiobridge,
    this.room,
    this.permanent,
  });

  AudioRoomCreatedResponse.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    permanent = json['permanent'];
  }
  String? audiobridge;
  dynamic room;
  bool? permanent;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;
    map['permanent'] = permanent;
    return map;
  }
}
