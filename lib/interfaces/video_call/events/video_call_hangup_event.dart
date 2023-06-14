part of janus_client;

class VideoCallHangupEvent {
  VideoCallHangupEvent({
    this.videocall,
    this.result,
  });

  VideoCallHangupEvent.fromJson(dynamic json) {
    videocall = json['videocall'];
    result = json['result'] != null ? HangupResult.fromJson(json['result']) : null;
  }
  String? videocall;
  HangupResult? result;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videocall'] = videocall;
    if (result != null) {
      map['result'] = result?.toJson();
    }
    return map;
  }
}

class HangupResult {
  HangupResult({
    this.event,
    this.username,
    this.reason,
  });

  HangupResult.fromJson(dynamic json) {
    event = json['event'];
    username = json['username'];
    reason = json['reason'];
  }
  String? event;
  String? username;
  String? reason;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['event'] = event;
    map['username'] = username;
    map['reason'] = reason;
    return map;
  }
}
