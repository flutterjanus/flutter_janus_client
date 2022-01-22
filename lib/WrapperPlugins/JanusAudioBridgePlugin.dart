import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/JanusClient.dart';

class JanusAudioBridgePlugin extends JanusPlugin {
  JanusAudioBridgePlugin({handleId, context, transport, session}) : super(context: context, handleId: handleId, plugin: JanusPlugins.AUDIO_BRIDGE, session: session, transport: transport);

  ///
  /// [createRoom]<br>
  /// this can be used to create a new audio room .<br>
  /// Notice that, in general, all users can create rooms. If you want to limit this functionality, you can configure an admin admin_key in the plugin settings. When configured, only "create" requests that include the correct admin_key value in an "admin_key" property will succeed, and will be rejected otherwise. Notice that you can optionally extend this functionality to RTP forwarding as well, in order to only allow trusted clients to use that feature.<br><br>
  ///[room] : unique numeric ID, optional, chosen by plugin if missing.<br>
  ///[permanent] : true|false, whether the room should be saved in the config file, default=false.<br>
  ///[description] : pretty name of the room, optional.<br>
  ///[secret] : password required to edit/destroy the room, optional.<br>
  ///[pin] : password required to join the room, optional.<br>
  ///[is_private] : true|false, whether the room should appear in a list request.<br>
  ///[allowed] : [ array of string tokens users can use to join this room, optional].<br>
  ///[sampling_rate] : sampling rate of the room, optional, 16000 by default.<br>
  ///[spatial_audio] : true|false, whether the mix should spatially place users, default=false.<br>
  ///[audiolevel_ext] : true|false, whether the ssrc-audio-level RTP extension must be negotiated for new joins, default=true.<br>
  ///[audiolevel_event] : true|false (whether to emit event to other users or not).<br>
  ///[audio_active_packets] : number of packets with audio level (default=100, 2 seconds).<br>
  ///[audio_level_average] : average value of audio level (127=muted, 0='too loud', default=25).<br>
  ///[default_prebuffering] : number of packets to buffer before decoding each participant (default=DEFAULT_PREBUFFERING).<br>
  ///[default_expectedloss] : percent of packets we expect participants may miss, to help with FEC (default=0, max=20; automatically used for forwarders too).<br>
  ///[default_bitrate] : bitrate in bps to use for the all participants (default=auto, libopus decides; automatically used for forwarders too).<br>
  ///[record] : true|false, whether to record the room or not, default=false.<br>
  ///[record_file] : /path/to/the/recording.wav, optional>.<br>
  ///[record_dir] : /path/to/, optional; makes record_file a relative path, if provided.<br>
  ///[allow_rtp_participants] : true|false, whether participants should be allowed to join via plain RTP as well, default=false.<br>
  ///[groups] : [ non-hierarchical array of string group names to use to gat participants, for external forwarding purposes only, optional].<br>
  ///
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
      "description": description,
      "secret": secret,
      "pin": pin,
      "is_private": is_private,
      "allowed": allowed,
      "sampling_rate": sampling_rate,
      "spatial_audio": spatial_audio,
      "audiolevel_ext": audiolevel_ext,
      "audiolevel_event": audiolevel_event,
      "audio_active_packets": audio_active_packets,
      "audio_level_average": audio_level_average,
      "default_prebuffering": default_prebuffering,
      "record": record,
      "record_file": record_file,
      "record_dir": record_dir,
      "allow_rtp_participants": allow_rtp_participants,
      "groups": groups
    }..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return AudioRoomCreatedResponse.fromJson(response.plugindata?.data);
  }

  Future<dynamic> editRoom(int roomId, {String? secret, String? newDescription, String? newSecret, String? newPin, bool? newIsPrivate, bool? permanent}) async {
    var payload = {
      "request": "edit",
      "room": roomId,
      "secret": secret,
      "new_description": newDescription,
      "new_secret": newSecret,
      "new_pin": newPin,
      "new_is_private": newIsPrivate,
      "permanent": permanent
    }..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return AudioRoomCreatedResponse.fromJson(response.plugindata?.data);
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
      "id": id,
      "group": group,
      "pin": pin,
      "display": display,
      "token": token,
      "muted": muted,
      "codec": codec,
      "prebuffer": preBuffer,
      "quality": quality,
      "volume": volume,
      "spatial_position": spatialPosition,
      "secret": secret,
      "audio_level_average": audioLevelAverage,
      "audio_active_packets": audioActivePackets,
      "record": record,
      "filename": filename
    }..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// [configure]
  ///
  /// muted instructs the plugin to mute or unmute the participant; quality changes the complexity of the Opus encoder for the participant; record can be used to record this participant's contribution to a Janus .mjr file, and filename to provide a basename for the path to save the file to (notice that this is different from the recording of a whole room: this feature only records the packets this user is sending, and is not related to the mixer stuff). A successful request will result in a ok event:<br><br>
  ///[muted] : true|false, whether to unmute or mute<br>
  ///[display] : new display name to have in the room"<br>
  ///[prebuffer] : new number of packets to buffer before decoding this participant (see "join" for more info)<br>
  ///[bitrate] : new bitrate to use for the Opus stream (see "join" for more info)<br>
  ///[quality] : new Opus-related complexity to use (see "join" for more info)<br>
  ///[expected_loss] : new value for the expected loss (see "join" for more info)<br>
  ///[volume] : new volume percent value (see "join" for more info)<br>
  ///[spatial_position] : in case spatial audio is enabled for the room, new panning of this participant (0=left, 50=center, 100=right)<br>
  ///[record] : true|false, whether to record this user's contribution to a .mjr file (mixer not involved)<br>
  ///[filename] : basename of the file to record to, -audio.mjr will be added by the plugin<br>
  ///[group] : new group to assign to this participant, if enabled in the room (for forwarding purposes)<br>
  Future<void> configure({bool? muted, String? display, int? prebuffer, int? quality, int? volume, int? spatial_position, bool? record, String? filename, String? group}) async {
    var payload = {
      "request": "configure",
      "muted": muted,
      "display": display,
      "prebuffer": prebuffer,
      "quality": quality,
      "volume": volume,
      "spatial_position": spatial_position,
      "record": record,
      "filename": filename,
      "group": group
    }..removeWhere((key, value) => value == null);
    RTCSessionDescription? offer = await this.createOffer(videoSend: false, videoRecv: false, audioSend: true, audioRecv: false);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload, jsep: offer));
    JanusError.throwErrorFromEvent(response);
  }

  /// [muteParticipant]
  ///
  /// If you're the administrator of a room (that is, you created it and have access to the secret) you can mute or unmute individual participants.
  /// [roomId] unique numeric ID of the room to stop the forwarder from.<br>
  /// [participantId] unique numeric ID of the participant.<br>
  /// [mute] toggle mute status of the participant.<br>
  /// [secret] admin secret should be provided if configured.<br>
  Future<dynamic> muteParticipant(int roomId, int participantId, bool mute, {String? secret}) async {
    var payload = {"request": mute ? 'mute' : 'unmute', "secret": secret, "room": roomId, "id": participantId}..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response.plugindata?.data;
  }

  /// [stopRtpForward]
  ///
  /// To stop a previously created RTP forwarder.<br>
  /// [roomId] unique numeric ID of the room to stop the forwarder from.<br>
  /// [streamId] unique numeric ID of the RTP forwarder.<br>
  Future<RtpForwardStopped> stopRtpForward(int roomId, int streamId) async {
    var payload = {"request": "stop_rtp_forward", "room": roomId, "stream_id": streamId};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return RtpForwardStopped.fromJson(response.plugindata?.data);
  }

  /// [rtpForward]
  ///
  /// You can add a new RTP forwarder for an existing room using the rtp_forward request.<br>
  /// [roomId] unique numeric ID of the room to add the forwarder to.<br>
  /// [group] to forward, if enabled in the room (forwards full mix if missing).<br>
  /// [host] address to forward the RTP packets to.<br>
  /// [ssrc] to use to use when streaming (optional: stream_id used if missing).<br>
  /// [codec] opus (default), pcma (A-Law) or pcmu (mu-Law).<br>
  /// [payload] type to use when streaming (optional: 100 used if missing).<br>
  /// [host_family] ipv4|ipv6, if we need to resolve the host address to an IP; by default, whatever we get.<br>
  /// [port] to forward the RTP packets to.<br>
  /// [srtp_suite] length of authentication tag (32 or 80); optional. <br>
  /// [always_on] true|false, whether silence should be forwarded when the room is empty.<br>
  /// [srtp_crypto] key to use as crypto (base64 encoded key as in SDES); optional.<br>
  /// [admin_key] key to use if admin_key is set for rtp forward as well.<br>
  Future<RtpForwarderCreated> rtpForward(int roomId, String host, int port,
      {String? group, String? admin_key, String? ssrc, String? codec, String? ptype, int? srtp_suite, bool? always_on, String? host_family, String? srtp_crypto}) async {
    var payload = {
      "request": "rtp_forward",
      "room": roomId,
      "admin_key": admin_key,
      "group": group,
      "ssrc": ssrc,
      "codec": codec,
      "ptype": ptype,
      "host": host,
      "host_family": host_family,
      "port": port,
      "srtp_suite": srtp_suite,
      "srtp_crypto": srtp_crypto,
      "always_on": always_on
    }..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return RtpForwarderCreated.fromJson(response.plugindata?.data);
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
