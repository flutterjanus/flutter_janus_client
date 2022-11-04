part of janus_client;

class VideoRoomJoinedEvent extends VideoRoomEvent {
  VideoRoomJoinedEvent({
    videoroom,
    room,
    this.description,
    this.id,
    this.privateId,
    this.publishers,
  }) {
    super.videoroom = videoroom;
    super.room = room;
  }

  VideoRoomJoinedEvent.fromJson(dynamic json) {
    videoroom = json['videoroom'];
    room = json['room'];
    description = json['description'];
    id = json['id'];
    privateId = json['private_id'];
    if (json['publishers'] != null) {
      publishers = [];
      json['publishers'].forEach((v) {
        publishers?.add(Publishers.fromJson(v));
      });
    }
  }

  String? description;
  dynamic id;
  int? privateId;
  List<Publishers>? publishers;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videoroom'] = videoroom;
    map['room'] = room;
    map['description'] = description;
    map['id'] = id;
    map['private_id'] = privateId;
    if (publishers != null) {
      map['publishers'] = publishers?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Publishers {
  Publishers({
    this.id,
    this.display,
    this.audioCodec,
    this.videoCodec,
    this.streams,
    this.talking,
  });

  Publishers.fromJson(dynamic json) {
    id = json['id'];
    display = json['display'];
    audioCodec = json['audio_codec'];
    videoCodec = json['video_codec'];
    if (json['streams'] != null) {
      streams = [];
      json['streams'].forEach((v) {
        streams?.add(Streams.fromMap(v));
      });
    }
    talking = json['talking'];
  }

  dynamic id;
  String? display;
  String? audioCodec;
  String? videoCodec;
  List<Streams>? streams;
  bool? talking;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['display'] = display;
    map['audio_codec'] = audioCodec;
    map['video_codec'] = videoCodec;
    if (streams != null) {
      map['streams'] = streams?.map((v) => v.toMap()).toList();
    }
    map['talking'] = talking;
    return map;
  }
}
