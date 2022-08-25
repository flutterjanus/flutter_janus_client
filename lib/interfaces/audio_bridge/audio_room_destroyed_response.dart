part of janus_client;

class AudioRoomDestroyedResponse {
  String? audiobridge;
  dynamic room;
  AudioRoomDestroyedResponse({this.audiobridge, this.room});
  AudioRoomDestroyedResponse.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;

    return map;
  }
}
