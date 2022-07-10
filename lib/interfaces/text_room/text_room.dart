part of janus_client;

/// room : 1234
/// description : "Demo Room"
/// pin_required : false
/// num_participants : 0
/// history : 0

class JanusTextRoom {
  JanusTextRoom({
    int? room,
    String? description,
    bool? pinRequired,
    int? numParticipants,
    int? history,
  }) {
    _room = room;
    _description = description;
    _pinRequired = pinRequired;
    _numParticipants = numParticipants;
    _history = history;
  }

  JanusTextRoom.fromJson(dynamic json) {
    _room = json['room'];
    _description = json['description'];
    _pinRequired = json['pin_required'];
    _numParticipants = json['num_participants'];
    _history = json['history'];
  }

  int? _room;
  String? _description;
  bool? _pinRequired;
  int? _numParticipants;
  int? _history;

  JanusTextRoom copyWith({
    int? room,
    String? description,
    bool? pinRequired,
    int? numParticipants,
    int? history,
  }) =>
      JanusTextRoom(
        room: room ?? _room,
        description: description ?? _description,
        pinRequired: pinRequired ?? _pinRequired,
        numParticipants: numParticipants ?? _numParticipants,
        history: history ?? _history,
      );

  int? get room => _room;

  String? get description => _description;

  bool? get pinRequired => _pinRequired;

  int? get numParticipants => _numParticipants;

  int? get history => _history;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['room'] = _room;
    map['description'] = _description;
    map['pin_required'] = _pinRequired;
    map['num_participants'] = _numParticipants;
    map['history'] = _history;
    return map;
  }
}
