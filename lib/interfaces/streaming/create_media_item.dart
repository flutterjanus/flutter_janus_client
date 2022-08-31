part of janus_client;

class CreateMediaItem {
  CreateMediaItem({
    this.type,
    this.mid,
    this.port,
  });

  CreateMediaItem.fromJson(dynamic json) {
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
