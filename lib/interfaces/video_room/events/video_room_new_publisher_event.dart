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
  dynamic feed;
  dynamic mid;

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
      (other is PublisherStream && runtimeType == other.runtimeType && simulcast == other.simulcast && svc == other.svc && feed == other.feed && mid == other.mid);

  @override
  int get hashCode => simulcast.hashCode ^ svc.hashCode ^ feed.hashCode ^ mid.hashCode;

  @override
  String toString() {
    return 'PublisherStream{' + ' simulcast: $simulcast,' + ' svc: $svc,' + ' feed: $feed,' + ' mid: $mid,' + '}';
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
      feed: map['feed'],
      mid: map['mid'],
    );
  }

//</editor-fold>
}

class SubscriberUpdateStream {
  dynamic feed;
  dynamic mid;
  dynamic crossrefid;
  SubscriberUpdateStream({
    required this.feed,
    required this.mid,
    required this.crossrefid,
  });

  SubscriberUpdateStream copyWith({
    dynamic feed,
    dynamic mid,
    dynamic crossrefid,
  }) {
    return SubscriberUpdateStream(
      feed: feed ?? this.feed,
      mid: mid ?? this.mid,
      crossrefid: crossrefid ?? this.crossrefid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feed': feed,
      'mid': mid,
      'crossrefid': crossrefid,
    };
  }

  factory SubscriberUpdateStream.fromMap(Map<String, dynamic> map) {
    return SubscriberUpdateStream(
      feed: map['feed'] ?? null,
      mid: map['mid'] ?? null,
      crossrefid: map['crossrefid'] ?? null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SubscriberUpdateStream.fromJson(String source) => SubscriberUpdateStream.fromMap(json.decode(source));

  @override
  String toString() => 'SubscriberUpdateStream(feed: $feed, mid: $mid, crossrefid: $crossrefid)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SubscriberUpdateStream && other.feed == feed && other.mid == mid && other.crossrefid == crossrefid;
  }

  @override
  int get hashCode => feed.hashCode ^ mid.hashCode ^ crossrefid.hashCode;
}

class Streams {
  bool? disabled;
  String? description;
  bool? moderated;
  bool? simulcast;
  bool? svc;
// new ones
  String? type;
  int? mindex;
  String? codec;
  String? mid;
  bool? fec;
  bool? talking;
  Streams({
    this.disabled,
    this.description,
    this.moderated,
    this.simulcast,
    this.svc,
    this.type,
    this.mindex,
    this.codec,
    this.mid,
    this.fec,
    this.talking,
  });

  Streams copyWith({
    bool? disabled,
    String? description,
    bool? moderated,
    bool? simulcast,
    bool? svc,
    String? type,
    int? mindex,
    String? codec,
    String? mid,
    bool? fec,
    bool? talking,
  }) {
    return Streams(
      disabled: disabled ?? this.disabled,
      description: description ?? this.description,
      moderated: moderated ?? this.moderated,
      simulcast: simulcast ?? this.simulcast,
      svc: svc ?? this.svc,
      type: type ?? this.type,
      mindex: mindex ?? this.mindex,
      codec: codec ?? this.codec,
      mid: mid ?? this.mid,
      fec: fec ?? this.fec,
      talking: talking ?? this.talking,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'disabled': disabled,
      'description': description,
      'moderated': moderated,
      'simulcast': simulcast,
      'svc': svc,
      'type': type,
      'mindex': mindex,
      'codec': codec,
      'mid': mid,
      'fec': fec,
      'talking': talking,
    };
  }

  factory Streams.fromMap(Map<String, dynamic> map) {
    return Streams(
      disabled: map['disabled'],
      description: map['description'],
      moderated: map['moderated'],
      simulcast: map['simulcast'],
      svc: map['svc'],
      type: map['type'],
      mindex: map['mindex']?.toInt(),
      codec: map['codec'],
      mid: map['mid'],
      fec: map['fec'],
      talking: map['talking'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Streams.fromJson(String source) => Streams.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Streams(disabled: $disabled, description: $description, moderated: $moderated, simulcast: $simulcast, svc: $svc, type: $type, mindex: $mindex, codec: $codec, mid: $mid, fec: $fec, talking: $talking)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Streams &&
        other.disabled == disabled &&
        other.description == description &&
        other.moderated == moderated &&
        other.simulcast == simulcast &&
        other.svc == svc &&
        other.type == type &&
        other.mindex == mindex &&
        other.codec == codec &&
        other.mid == mid &&
        other.fec == fec &&
        other.talking == talking;
  }

  @override
  int get hashCode {
    return disabled.hashCode ^
        description.hashCode ^
        moderated.hashCode ^
        simulcast.hashCode ^
        svc.hashCode ^
        type.hashCode ^
        mindex.hashCode ^
        codec.hashCode ^
        mid.hashCode ^
        fec.hashCode ^
        talking.hashCode;
  }
}

class UnsubscribeStreams {
  dynamic feed;
  dynamic mid;
  dynamic subMid;
  UnsubscribeStreams({
    required this.feed,
    required this.mid,
    required this.subMid,
  });

  UnsubscribeStreams copyWith({
    dynamic feed,
    dynamic mid,
    dynamic subMid,
  }) {
    return UnsubscribeStreams(
      feed: feed ?? this.feed,
      mid: mid ?? this.mid,
      subMid: subMid ?? this.subMid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feed': feed,
      'mid': mid,
      'sub_mid': subMid,
    };
  }

  factory UnsubscribeStreams.fromMap(Map<String, dynamic> map) {
    return UnsubscribeStreams(
      feed: map['feed'] ?? null,
      mid: map['mid'] ?? null,
      subMid: map['sub_mid'] ?? null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UnsubscribeStreams.fromJson(String source) => UnsubscribeStreams.fromMap(json.decode(source));

  @override
  String toString() => 'UnsubscribeStreams(feed: $feed, mid: $mid, subMid: $subMid)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UnsubscribeStreams && other.feed == feed && other.mid == mid && other.subMid == subMid;
  }

  @override
  int get hashCode => feed.hashCode ^ mid.hashCode ^ subMid.hashCode;
}
