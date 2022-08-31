part of janus_client;

class VideoRoomConfigured extends VideoRoomEvent {
  VideoRoomConfigured({
    videoroom,
    this.configured,
  }) {
    super.videoroom = videoroom;
    super.room = 0;
  }

  VideoRoomConfigured.fromJson(dynamic json) {
    videoroom = json['videoroom'];
    configured = json['configured'];
  }

  String? configured;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videoroom'] = videoroom;
    map['configured'] = configured;
    return map;
  }
}
