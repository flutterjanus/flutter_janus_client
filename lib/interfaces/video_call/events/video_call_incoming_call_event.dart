part of janus_client;

class VideoCallIncomingCallEvent extends VideoCallEvent {
  VideoCallIncomingCallEvent.fromJson(dynamic json) {
    videocall = json['videocall'];
    result = json['result'] != null ? Result.fromJson(json['result']) : null;
  }
}
