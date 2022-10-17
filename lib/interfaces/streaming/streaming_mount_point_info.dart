part of janus_client;

class StreamingMountPointInfo {
  StreamingMountPointInfo({
    this.id,
    this.name,
    this.description,
    this.metadata,
    this.secret,
    this.pin,
    this.isPrivate,
    this.viewers,
    this.enabled,
    this.type,
    this.media,
  });

  StreamingMountPointInfo.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    metadata = json['metadata'];
    secret = json['secret'];
    pin = json['pin'];
    isPrivate = json['is_private'];
    viewers = json['viewers'];
    enabled = json['enabled'];
    type = json['type'];
    if (json['media'] != null) {
      media = [];
      json['media'].forEach((v) {
        media?.add(Media.fromJson(v));
      });
    }
  }
  int? id;
  String? name;
  String? description;
  String? metadata;
  String? secret;
  String? pin;
  bool? isPrivate;
  int? viewers;
  bool? enabled;
  String? type;
  List<Media>? media;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['description'] = description;
    map['metadata'] = metadata;
    map['secret'] = secret;
    map['pin'] = pin;
    map['is_private'] = isPrivate;
    map['viewers'] = viewers;
    map['enabled'] = enabled;
    map['type'] = type;
    if (media != null) {
      map['media'] = media?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Media {
  Media({
    this.mid,
    this.mindex,
    this.type,
    this.label,
    this.ageMs,
    this.pt,
    this.rtpmap,
    this.fmtp,
  });

  Media.fromJson(dynamic json) {
    mid = json['mid'];
    mindex = json['mindex'];
    type = json['type'];
    label = json['label'];
    ageMs = json['age_ms'];
    pt = json['pt'];
    rtpmap = json['rtpmap'];
    fmtp = json['fmtp'];
  }
  String? mid;
  String? mindex;
  String? type;
  String? label;
  int? ageMs;
  String? pt;
  String? rtpmap;
  String? fmtp;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['mid'] = mid;
    map['mindex'] = mindex;
    map['type'] = type;
    map['label'] = label;
    map['age_ms'] = ageMs;
    map['pt'] = pt;
    map['rtpmap'] = rtpmap;
    map['fmtp'] = fmtp;
    return map;
  }
}
