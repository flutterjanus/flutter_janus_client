part of janus_client;

class StreamingMountPoint {
  StreamingMountPoint({
    this.id,
    this.type,
    this.description,
    this.metadata,
    this.enabled,
    this.media,
  });

  StreamingMountPoint.fromJson(dynamic json) {
    id = json['id'];
    type = json['type'];
    description = json['description'];
    metadata = json['metadata'];
    enabled = json['enabled'];
    if (json['media'] != null) {
      media = [];
      json['media'].forEach((v) {
        media?.add(Media.fromJson(v));
      });
    }
  }
  int? id;
  String? type;
  String? description;
  String? metadata;
  bool? enabled;
  List<Media>? media;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['type'] = type;
    map['description'] = description;
    map['metadata'] = metadata;
    map['enabled'] = enabled;
    if (media != null) {
      map['media'] = media?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
