part of janus_client;

class VideoRoomAttachedEvent {
  VideoRoomAttachedEvent({
    this.videoroom,
    this.room,
    this.streams,
  });

  VideoRoomAttachedEvent.fromJson(dynamic json) {
    videoroom = json['videoroom'];
    room = json['room'];
    if (json['streams'] != null) {
      streams = [];
      json['streams'].forEach((v) {
        streams?.add(AttachedStreams.fromJson(v));
      });
    }
  }
  String? videoroom;
  dynamic room;
  List<AttachedStreams>? streams;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videoroom'] = videoroom;
    map['room'] = room;
    if (streams != null) {
      map['streams'] = streams?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class AttachedStreams extends BaseStream {
  AttachedStreams({
    mindex,
    mid,
    type,
    this.feedId,
    this.feedMid,
    this.feedDisplay,
    this.send,
    this.ready,
  }) {
    super.mid = mid;
    super.mindex = mindex;
    super.type = type;
  }

  AttachedStreams.fromJson(dynamic json) {
    mindex = json['mindex'];
    mid = json['mid'];
    type = json['type'];
    feedId = json['feed_id'];
    feedMid = json['feed_mid'];
    feedDisplay = json['feed_display'];
    send = json['send'];
    ready = json['ready'];
  }
  dynamic feedId;
  dynamic feedMid;
  String? feedDisplay;
  bool? send;
  bool? ready;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['mindex'] = mindex;
    map['mid'] = mid;
    map['type'] = type;
    map['feed_id'] = feedId;
    map['feed_mid'] = feedMid;
    map['feed_display'] = feedDisplay;
    map['send'] = send;
    map['ready'] = ready;
    return map;
  }
}
