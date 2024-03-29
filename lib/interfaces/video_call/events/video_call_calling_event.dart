part of janus_client;

class VideoCallCallingEvent extends VideoCallEvent {
  VideoCallCallingEvent.fromJson(dynamic json) {
    videocall = json['videocall'];
    result = json['result'] != null ? Result.fromJson(json['result']) : null;
  }
}

class VideoCallUpdateEvent {
  String videocall = 'videocall';
  dynamic result;
  VideoCallUpdateEvent.fromJson(dynamic json) {
    videocall = json['videocall'];
  }
}
