part of janus_client;

class VideoRoomEvent {
  late String videoroom;
  dynamic room;

//<editor-fold desc="Data Methods">
  VideoRoomEvent.create(videoroom, room) {
    this.videoroom = videoroom;
    room = room;
  }

  VideoRoomEvent() {
    this.videoroom = '';
    room = 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoRoomEvent &&
          runtimeType == other.runtimeType &&
          videoroom == other.videoroom &&
          room == other.room);

  @override
  int get hashCode => videoroom.hashCode ^ room.hashCode;

  @override
  String toString() {
    return 'VideoRoomEvent{' +
        ' videoroom: $videoroom,' +
        ' room: $room,' +
        '}';
  }

  VideoRoomEvent copyWith({
    String? videoroom,
    int? room,
  }) {
    return VideoRoomEvent.create(
      videoroom ?? this.videoroom,
      room ?? this.room,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoroom': this.videoroom,
      'room': this.room,
    };
  }

  factory VideoRoomEvent.fromMap(Map<String, dynamic> map) {
    return VideoRoomEvent.create(
      map['videoroom'] as String,
      map['room'] as int,
    );
  }

//</editor-fold>
}

class BaseStream {
  int? mindex;
  String? mid;
  String? type;
}
