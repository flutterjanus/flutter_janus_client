part of janus_client;

class VideoRoomLeavingEvent extends VideoRoomEvent {
  VideoRoomLeavingEvent({
    videoroom,
    room,
    this.leaving,
  }) {
    super.room = room;
    super.videoroom = videoroom;
  }

  VideoRoomLeavingEvent.fromJson(dynamic json) {
    videoroom = json['videoroom'];
    room = json['room'];
    leaving = json['leaving'];
  }
  int? leaving;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videoroom'] = videoroom;
    map['room'] = room;
    map['leaving'] = leaving;
    return map;
  }
}
