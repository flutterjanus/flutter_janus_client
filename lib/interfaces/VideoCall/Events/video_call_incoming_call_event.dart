import './events.dart';
class VideoCallIncomingCallEvent extends VideoCallEvent{
  VideoCallIncomingCallEvent.fromJson(dynamic json) {
    videocall = json['videocall'];
    result = json['result'] != null ? Result.fromJson(json['result']) : null;
  }
}
