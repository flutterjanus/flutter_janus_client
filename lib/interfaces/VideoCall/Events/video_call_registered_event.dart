import './events.dart';
class VideoCallRegisteredEvent extends VideoCallEvent {
  VideoCallRegisteredEvent.fromJson(dynamic json) {
    videocall = json['videocall'];
    result = json['result'] != null ? Result.fromJson(json['result']) : null;
  }
}
