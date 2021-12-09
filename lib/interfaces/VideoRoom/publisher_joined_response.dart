class PublisherJoinedResponse {
  PublisherJoinedResponse({
      this.videoroom, 
      this.room, 
      this.description, 
      this.id, 
      this.privateId, 
      this.publishers, 
      this.attendees,});

  PublisherJoinedResponse.fromJson(dynamic json) {
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
    if (json['attendees'] != null) {
      attendees = [];
      json['attendees'].forEach((v) {
        attendees?.add(Attendees.fromJson(v));
      });
    }
  }
  String? videoroom;
  String? room;
  String? description;
  String? id;
  String? privateId;
  List<Publishers>? publishers;
  List<Attendees>? attendees;

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
    if (attendees != null) {
      map['attendees'] = attendees?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

class Attendees {
  Attendees({
      this.id, 
      this.display,});

  Attendees.fromJson(dynamic json) {
    id = json['id'];
    display = json['display'];
  }
  String? id;
  String? display;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['display'] = display;
    return map;
  }

}

class Publishers {
  Publishers({
      this.id, 
      this.display, 
      this.streams, 
      this.talking,});

  Publishers.fromJson(dynamic json) {
    id = json['id'];
    display = json['display'];
    if (json['streams'] != null) {
      streams = [];
      json['streams'].forEach((v) {
        streams?.add(Streams.fromJson(v));
      });
    }
    talking = json['talking'];
  }
  String? id;
  String? display;
  List<Streams>? streams;
  bool? talking;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['display'] = display;
    if (streams != null) {
      map['streams'] = streams?.map((v) => v.toJson()).toList();
    }
    map['talking'] = talking;
    return map;
  }

}

class Streams {
  Streams({
      this.type, 
      this.mindex, 
      this.mid, 
      this.disabled, 
      this.codec, 
      this.description, 
      this.moderated, 
      this.simulcast, 
      this.svc, 
      this.talking,});

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
  String? type;
  String? mindex;
  String? mid;
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