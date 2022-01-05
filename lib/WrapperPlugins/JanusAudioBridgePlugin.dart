import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/JanusClient.dart';

class JanusAudioBridgePlugin extends JanusPlugin {
  JanusAudioBridgePlugin({handleId, context, transport, session}) : super(context: context, handleId: handleId, plugin: JanusPlugins.AUDIO_BRIDGE, session: session, transport: transport);

  Future<AudioRoomCreatedResponse> createRoom(int roomId,
      {bool permanent = true,
      String? description,
      String? secret,
      String? pin,
      bool? is_private,
      bool? audiolevel_ext,
      bool? audiolevel_event,
      int? audio_active_packets,
      int? audio_level_average,
      List<String>? allowed,
      bool? record,
      String? record_file,
      String? record_dir,
      String? default_prebuffering,
      String? allow_rtp_participants,
      int? sampling_rate,
      List<String>? groups,
      bool? spatial_audio}) async {
    var payload = {
      "request": "create",
      "room": roomId,
      "permanent": permanent,
      if (description != null) "description": description,
      if (secret != null) "secret": secret,
      if (pin != null) "pin": pin,
      if (is_private != null) "is_private": is_private,
      if (allowed != null) "allowed": allowed,
      if (sampling_rate != null) "sampling_rate": sampling_rate,
      if (spatial_audio != null) "spatial_audio": spatial_audio,
      if (audiolevel_ext != null) "audiolevel_ext": audiolevel_ext,
      if (audiolevel_event != null) "audiolevel_event": audiolevel_event,
      if (audio_active_packets != null) "audio_active_packets": audio_active_packets,
      if (audio_level_average != null) "audio_level_average": audio_level_average,
      if (default_prebuffering != null) "default_prebuffering": default_prebuffering,
      if (record != null) "record": record,
      if (record_file != null) "record_file": record_file,
      if (record_dir != null) "record_dir": record_dir,
      if (allow_rtp_participants != null) "allow_rtp_participants": allow_rtp_participants,
      if (groups != null) "groups": groups
    };
    Map data = await this.send(data: payload);
    return AudioRoomCreatedResponse.fromJson(data);
  }

  Future<dynamic> editRoom(int roomId, {String? secret, String? newDescription, String? newSecret, String? newPin, bool? newIsPrivate, bool? permanent}) async {
    var payload = {
      "request": "edit",
      "room": roomId,
      if (secret != null) "secret": secret,
      if (newDescription != null) "new_description": newDescription,
      if (newSecret != null) "new_secret": newSecret,
      if (newPin != null) "new_pin": newPin,
      if (newIsPrivate != null) "new_is_private": newIsPrivate,
      if (permanent != null) "permanent": permanent
    };
    Map data = await this.send(data: payload);
    return AudioRoomCreatedResponse.fromJson(data);
  }

  Future<void> joinRoom(int roomId,
      {String? id,
      String? group,
      String? pin,
      String? display,
      String? token,
      bool? muted,
      String? codec,
      String? preBuffer,
      int? quality,
      int? volume,
      int? spatialPosition,
      String? secret,
      String? audioLevelAverage,
      String? audioActivePackets,
      bool? record,
      String? filename}) async {
    Map<String, dynamic> payload = {
      "request": "join",
      "room": roomId,
      if (id != null) "id": id,
      if (group != null) "group": group,
      if (pin != null) "pin": pin,
      if (display != null) "display": display,
      if (token != null) "token": token,
      if (muted != null) "muted": muted,
      if (codec != null) "codec": codec,
      if (preBuffer != null) "prebuffer": preBuffer,
      if (quality != null) "quality": quality,
      if (volume != null) "volume": volume,
      if (spatialPosition != null) "spatial_position": spatialPosition,
      if (secret != null) "secret": secret,
      if (audioLevelAverage != null) "audio_level_average": audioLevelAverage,
      if (audioActivePackets != null) "audio_active_packets": audioActivePackets,
      if (record != null) "record": record,
      if (filename != null) "filename": filename
    };
    Map data = await this.send(data: payload);
  }

  Future<void> configure({bool? muted, String? display, int? prebuffer, int? quality, int? volume, int? spatial_position, bool? record, String? filename, String? group}) async {
    var payload = {
      "request": "configure",
      if (muted != null) "muted": muted,
      if (display != null) "display": display,
      if (prebuffer != null) "prebuffer": prebuffer,
      if (quality != null) "quality": quality,
      if (volume != null) "volume": volume,
      if (spatial_position != null) "spatial_position": spatial_position,
      if (record != null) "record": record,
      if (filename != null) "filename": filename,
      if (group != null) "group": group
    };
    RTCSessionDescription? offer = await this.createOffer(videoSend: false, videoRecv: false, audioSend: true, audioRecv: false);
    Map data = await this.send(data: payload, jsep: offer);
  }

  bool _onCreated = false;

  @override
  void onCreate() {
    super.onCreate();
    if (!_onCreated) {
      _onCreated = true;
      messages?.listen((event) {
        TypedEvent<JanusEvent> typedEvent = TypedEvent<JanusEvent>(event: JanusEvent.fromJson(event.event), jsep: event.jsep);
        if (typedEvent.event.plugindata?.data["audiobridge"] == "joined") {
          typedEvent.event.plugindata?.data = AudioBridgeJoinedEvent.fromJson(typedEvent.event.plugindata?.data);
          typedMessagesSink?.add(typedEvent);
        }
      });
    }
  }
}
