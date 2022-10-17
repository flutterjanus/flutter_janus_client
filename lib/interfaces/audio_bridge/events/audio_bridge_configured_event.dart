part of janus_client;

class AudioBridgeConfiguredEvent {
  AudioBridgeConfiguredEvent({
    this.audiobridge,
    this.room,
    this.result,
  });

  AudioBridgeConfiguredEvent.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    result = json['result'];
  }
  String? audiobridge;
  dynamic room;
  String? result;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;
    map['result'] = result;
    return map;
  }
}
