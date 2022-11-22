part of janus_client;

class AudioBridgeDestroyedEvent extends AudioBridgeEvent {
  AudioBridgeDestroyedEvent({audiobridge, room}) {
    super.audiobridge = audiobridge;
    super.room = room;
  }

  AudioBridgeDestroyedEvent.fromJson(dynamic json) {
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
