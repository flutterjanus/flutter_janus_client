part of janus_client;

class AudioBridgeLeavingEvent extends AudioBridgeEvent {
  AudioBridgeLeavingEvent({audiobridge, room, this.leaving}) {
    super.audiobridge = audiobridge;
    super.room = room;
  }

  AudioBridgeLeavingEvent.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    leaving = json['leaving'];
  }

  int? leaving;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;
    map['leaving'] = leaving;
    return map;
  }
}
