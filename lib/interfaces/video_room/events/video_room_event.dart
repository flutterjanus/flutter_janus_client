part of janus_client;

class VideoRoomEvent {
  String? videoroom;
  dynamic room;

//<editor-fold desc="Data Methods">
  VideoRoomEvent.create(videoroom, room) {
    this.videoroom = videoroom;
    room = room;
  }

  VideoRoomEvent();

  @override
  bool operator ==(Object other) => identical(this, other) || (other is VideoRoomEvent && runtimeType == other.runtimeType && videoroom == other.videoroom && room == other.room);

  @override
  int get hashCode => videoroom.hashCode ^ room.hashCode;

  @override
  String toString() {
    return 'VideoRoomEvent{' + ' videoroom: $videoroom,' + ' room: $room,' + '}';
  }

  Map<String, dynamic> toMap() {
    return {
      'videoroom': this.videoroom,
      'room': this.room,
    };
  }

//</editor-fold>
}

class BaseStream {
  int? mindex;
  String? mid;
  String? type;
}
