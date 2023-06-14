part of janus_client;

class StreamingMount {
  StreamingMount({
    this.streaming,
    this.create,
    this.permanent,
    this.stream,
  });

  StreamingMount.fromJson(dynamic json) {
    streaming = json['streaming'];
    create = json['create'];
    permanent = json['permanent'];
    stream = json['stream'] != null ? StreamingPluginStream.fromJson(json['stream']) : null;
  }
  String? streaming;
  String? create;
  bool? permanent;
  StreamingPluginStream? stream;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['streaming'] = streaming;
    map['create'] = create;
    map['permanent'] = permanent;
    if (stream != null) {
      map['stream'] = stream?.toJson();
    }
    return map;
  }
}

class StreamingPluginStream {
  StreamingPluginStream({
    this.id,
    this.type,
    this.description,
    this.isPrivate,
    this.ports,
  });

  StreamingPluginStream.fromJson(dynamic json) {
    id = json['id'];
    type = json['type'];
    description = json['description'];
    isPrivate = json['is_private'];
    if (json['ports'] != null) {
      ports = [];
      json['ports'].forEach((v) {
        ports?.add(Ports.fromJson(v));
      });
    }
  }
  int? id;
  String? type;
  String? description;
  bool? isPrivate;
  List<Ports>? ports;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['type'] = type;
    map['description'] = description;
    map['is_private'] = isPrivate;
    if (ports != null) {
      map['ports'] = ports?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Ports {
  Ports({
    this.type,
    this.mid,
    this.port,
  });

  Ports.fromJson(dynamic json) {
    type = json['type'];
    mid = json['mid'];
    port = json['port'];
  }
  String? type;
  String? mid;
  int? port;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    map['mid'] = mid;
    map['port'] = port;
    return map;
  }
}
