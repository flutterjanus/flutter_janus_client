part of janus_client;

class VideoRoomUpdatedEvent extends VideoRoomEvent {
  VideoRoomUpdatedEvent({
    videoroom,
    this.streams,
  }) {
    super.videoroom = videoroom;
    super.room = 0;
  }

  VideoRoomUpdatedEvent.fromJson(dynamic json) {
    videoroom = json['videoroom'];
    room = json['room'];
    if (json['streams'] != null) {
      streams = [];
      json['streams'].forEach((v) {
        streams?.add(AttachedStreams.fromJson(v));
      });
    }
  }

  List<AttachedStreams>? streams;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videoroom'] = videoroom;
    map['room'] = room;
    if (streams != null) {
      map['streams'] = streams?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
