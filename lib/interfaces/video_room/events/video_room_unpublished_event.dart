part of janus_client;

class VideoRoomUnPublishedEvent extends VideoRoomEvent {
  VideoRoomUnPublishedEvent({
    videoroom,
    room,
    this.unpublished,
  }) {
    super.room = room;
    super.videoroom = videoroom;
  }

  VideoRoomUnPublishedEvent.fromJson(dynamic json) {
    videoroom = json['videoroom'];
    room = json['room'];
    unpublished = json['unpublished'];
  }
  dynamic unpublished;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videoroom'] = videoroom;
    map['room'] = room;
    map['unpublished'] = unpublished;
    return map;
  }
}
