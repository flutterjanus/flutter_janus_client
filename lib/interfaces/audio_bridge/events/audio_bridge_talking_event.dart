part of janus_client;

class AudioBridgeTalkingEvent extends AudioBridgeEvent {
  dynamic userId;
  bool? isTalking;
  AudioBridgeTalkingEvent({audiobridge, room, userId, isTalking}) {
    super.audiobridge = audiobridge;
    super.room = room;
    this.userId = userId;
    this.isTalking = isTalking;
  }

  AudioBridgeTalkingEvent.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    userId = json['id'];
    isTalking = json['audiobridge'] == 'talking'
        ? true
        : json['audiobridge'] == 'stopped-talking'
            ? false
            : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;
    map['id'] = userId;
    map['isTalking'] = isTalking;
    return map;
  }
}
