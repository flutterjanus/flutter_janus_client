class JanusVideoRoomEvent {
  JanusVideoRoomEvent({
      this.janus, 
      this.sessionId, 
      this.transaction, 
      this.sender, 
      this.plugindata,});

  JanusVideoRoomEvent.fromJson(dynamic json) {
    janus = json['janus'];
    sessionId = json['session_id'];
    transaction = json['transaction'];
    sender = json['sender'];
    plugindata = json['plugindata'] != null ? Plugindata.fromJson(json['plugindata']) : null;
  }
  String? janus;
  int? sessionId;
  String? transaction;
  int? sender;
  Plugindata? plugindata;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['janus'] = janus;
    map['session_id'] = sessionId;
    map['transaction'] = transaction;
    map['sender'] = sender;
    if (plugindata != null) {
      map['plugindata'] = plugindata?.toJson();
    }
    return map;
  }

}

class Plugindata {
  Plugindata({
      this.plugin, 
      this.data,});

  Plugindata.fromJson(dynamic json) {
    plugin = json['plugin'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  String? plugin;
  Data? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['plugin'] = plugin;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

class Data {
  Data({
      this.videoroom, 
      this.room, 
      this.description, 
      this.id, 
      this.privateId, 
      this.publishers,});

  Data.fromJson(dynamic json) {
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
  String? videoroom;
  int? room;
  String? description;
  int? id;
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
      this.talking,});

  Publishers.fromJson(dynamic json) {
    id = json['id'];
    display = json['display'];
    audioCodec = json['audio_codec'];
    videoCodec = json['video_codec'];
    if (json['streams'] != null) {
      streams = [];
      json['streams'].forEach((v) {
        streams?.add(Streams.fromJson(v));
      });
    }
    talking = json['talking'];
  }
  int? id;
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
      this.codec, 
      this.talking,});

  Streams.fromJson(dynamic json) {
    type = json['type'];
    mindex = json['mindex'];
    mid = json['mid'];
    codec = json['codec'];
    talking = json['talking'];
  }
  String? type;
  int? mindex;
  String? mid;
  String? codec;
  bool? talking;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['mindex'] = mindex;
    map['mid'] = mid;
    map['codec'] = codec;
    map['talking'] = talking;
    return map;
  }

}