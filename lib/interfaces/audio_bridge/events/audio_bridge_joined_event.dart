// ignore_for_file: public_member_api_docs, sort_constructors_first
part of janus_client;

class AudioBridgeJoinedEvent extends AudioBridgeEvent {
  AudioBridgeJoinedEvent({
    audiobridge,
    room,
    this.id,
    this.display,
    this.participants,
  }) {
    super.audiobridge = audiobridge;
    super.room = room;
  }

  AudioBridgeJoinedEvent.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    id = json['id'];
    display = json['display'];
    if (json['participants'] != null) {
      participants = [];
      json['participants'].forEach((v) {
        participants?.add(AudioBridgeParticipants.fromJson(v));
      });
    }
  }
  dynamic id;
  String? display;
  List<AudioBridgeParticipants>? participants;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;
    map['id'] = id;
    map['display'] = display;
    if (participants != null) {
      map['participants'] = participants?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class AudioBridgeParticipants {
  dynamic id;
  String? display;
  bool? setup;
  bool? muted;
  bool? talking;
  int? spatialPosition;

  AudioBridgeParticipants({
    this.id,
    this.display,
    this.setup = false,
    this.muted = false,
    this.talking = false,
    this.spatialPosition,
  });

  AudioBridgeParticipants.fromJson(dynamic json) {
    id = json['id'];
    display = json['display'];
    setup = json['setup'] != null ? json['setup'] : setup;
    muted = json['muted'] != null ? json['muted'] : muted;
    talking = json['talking'] != null ? json['talking'] : talking;
    spatialPosition = json['spatial_position'];
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['display'] = display;
    map['setup'] = setup;
    map['muted'] = muted;
    map['talking'] = talking;
    map['spatial_position'] = spatialPosition;
    return map;
  }

  AudioBridgeParticipants copyWith({
    int? id,
    String? display,
    bool? setup,
    bool? muted,
    bool? talking,
    int? spatialPosition,
  }) {
    return AudioBridgeParticipants(
      id: id ?? this.id,
      display: display ?? this.display,
      setup: setup ?? this.setup,
      muted: muted ?? this.muted,
      talking: talking ?? this.talking,
      spatialPosition: spatialPosition ?? this.spatialPosition,
    );
  }
}

class AudioBridgeNewParticipantsEvent extends AudioBridgeEvent {
  List<AudioBridgeParticipants>? participants;
  AudioBridgeNewParticipantsEvent.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    if (json['participants'] != null) {
      participants = [];
      json['participants'].forEach((v) {
        participants?.add(AudioBridgeParticipants.fromJson(v));
      });
    }
  }
}
