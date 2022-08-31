part of janus_client;

class StreamingMountEdited {
  StreamingMountEdited({
    this.streaming,
    this.id,
    this.permanent,
  });

  StreamingMountEdited.fromJson(dynamic json) {
    streaming = json['streaming'];
    id = json['id'];
    permanent = json['permanent'];
  }
  String? streaming;
  int? id;
  bool? permanent;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['streaming'] = streaming;
    map['id'] = id;
    map['permanent'] = permanent;
    return map;
  }
}
