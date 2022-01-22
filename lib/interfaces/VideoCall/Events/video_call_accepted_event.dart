import './events.dart';
class VideoCallAcceptedEvent extends VideoCallEvent {
  VideoCallAcceptedEvent.fromJson(dynamic json) {
    videocall = json['videocall'];
    result = json['result'] != null ? Result.fromJson(json['result']) : null;
  }
}
