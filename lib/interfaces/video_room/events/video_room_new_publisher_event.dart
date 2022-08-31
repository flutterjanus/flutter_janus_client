part of janus_client;

class VideoRoomNewPublisherEvent extends VideoRoomEvent {
  VideoRoomNewPublisherEvent({
    videoroom,
    room,
    this.publishers,
  }) {
    super.videoroom = videoroom;
    super.room = room;
  }

  VideoRoomNewPublisherEvent.fromJson(dynamic json) {
    videoroom = json['videoroom'];
    room = json['room'];
    if (json['publishers'] != null) {
      publishers = [];
      json['publishers'].forEach((v) {
        publishers?.add(Publishers.fromJson(v));
      });
    }
  }

  List<Publishers>? publishers;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videoroom'] = videoroom;
    map['room'] = room;
    if (publishers != null) {
      map['publishers'] = publishers?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class PublisherStream {
  bool? simulcast;
  bool? svc;
  int? feed;
  String? mid;

//<editor-fold desc="Data Methods">

  PublisherStream({
    this.simulcast,
    this.svc,
    this.feed,
    this.mid,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PublisherStream &&
          runtimeType == other.runtimeType &&
          simulcast == other.simulcast &&
          svc == other.svc &&
          feed == other.feed &&
          mid == other.mid);

  @override
  int get hashCode =>
      simulcast.hashCode ^ svc.hashCode ^ feed.hashCode ^ mid.hashCode;

  @override
  String toString() {
    return 'PublisherStream{' +
        ' simulcast: $simulcast,' +
        ' svc: $svc,' +
        ' feed: $feed,' +
        ' mid: $mid,' +
        '}';
  }

  PublisherStream copyWith({
    bool? simulcast,
    bool? svc,
    int? feed,
    String? mid,
  }) {
    return PublisherStream(
      simulcast: simulcast ?? this.simulcast,
      svc: svc ?? this.svc,
      feed: feed ?? this.feed,
      mid: mid ?? this.mid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'simulcast': this.simulcast,
      'svc': this.svc,
      'feed': this.feed,
      'mid': this.mid,
    };
  }

  factory PublisherStream.fromMap(Map<String, dynamic> map) {
    return PublisherStream(
      simulcast: map['simulcast'] as bool,
      svc: map['svc'] as bool,
      feed: map['feed'] as int,
      mid: map['mid'] as String,
    );
  }

//</editor-fold>
}

class Streams extends BaseStream {
  Streams.fromJson(dynamic json) {
    type = json['type'];
    mindex = json['mindex'];
    mid = json['mid'];
    disabled = json['disabled'];
    codec = json['codec'];
    description = json['description'];
    moderated = json['moderated'];
    simulcast = json['simulcast'];
    svc = json['svc'];
    talking = json['talking'];
  }

  bool? disabled;
  String? codec;
  String? description;
  bool? moderated;
  bool? simulcast;
  bool? svc;
  bool? talking;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['mindex'] = mindex;
    map['mid'] = mid;
    map['disabled'] = disabled;
    map['codec'] = codec;
    map['description'] = description;
    map['moderated'] = moderated;
    map['simulcast'] = simulcast;
    map['svc'] = svc;
    map['talking'] = talking;
    return map;
  }
}
