part of janus_client;

class JanusAudioBridgePlugin extends JanusPlugin {
  JanusAudioBridgePlugin({handleId, context, transport, session})
      : super(context: context, handleId: handleId, plugin: JanusPlugins.AUDIO_BRIDGE, session: session, transport: transport);

  ///
  /// [createRoom]<br>
  /// this can be used to create a new audio room .<br>
  /// Notice that, in general, all users can create rooms. If you want to limit this functionality, you can configure an admin adminKey in the plugin settings. When configured, only "create" requests that include the correct adminKey value in an "adminKey" property will succeed, and will be rejected otherwise. Notice that you can optionally extend this functionality to RTP forwarding as well, in order to only allow trusted clients to use that feature.<br><br>
  ///[roomId] : unique numeric ID, optional, chosen by plugin if missing.<br>
  ///[permanent] : true|false, whether the room should be saved in the config file, default=false.<br>
  ///[description] : pretty name of the room, optional.<br>
  ///[secret] : password required to edit/destroy the room, optional.<br>
  ///[pin] : password required to join the room, optional.<br>
  ///[isPrivate] : true|false, whether the room should appear in a list request.<br>
  ///[allowed] :  array of string tokens users can use to join this room, optional.<br>
  ///[samplingRate] : sampling rate of the room, optional, 16000 by default.<br>
  ///[spatialAudio] : true|false, whether the mix should spatially place users, default=false.<br>
  ///[audioLevelExt] : true|false, whether the ssrc-audio-level RTP extension must be negotiated for new joins, default=true.<br>
  ///[audioLevelEvent] : true|false (whether to emit event to other users or not).<br>
  ///[audioActivePackets] : number of packets with audio level (default=100, 2 seconds).<br>
  ///[audioLevelAverage] : average value of audio level (127=muted, 0='too loud', default=25).<br>
  ///[defaultPreBuffering] : number of packets to buffer before decoding each participant (default=DEFAULT_PREBUFFERING).<br>
  ///[defaultExpectedLoss] : percent of packets we expect participants may miss, to help with FEC (default=0, max=20; automatically used for forwarders too).<br>
  ///[defaultBitRate] : bitrate in bps to use for the all participants (default=auto, libopus decides; automatically used for forwarders too).<br>
  ///[record] : true|false, whether to record the room or not, default=false.<br>
  ///[recordFile] : /path/to/the/recording.wav, optional>.<br>
  ///[recordDir] : /path/to/, optional; makes recordFile a relative path, if provided.<br>
  ///[allowRtpParticipants] : true|false, whether participants should be allowed to join via plain RTP as well, default=false.<br>
  ///[groups] :  non-hierarchical array of string group names to use to gat participants, for external forwarding purposes only, optional.<br>
  ///
  Future<AudioRoomCreatedResponse> createRoom(dynamic roomId,
      {bool permanent = true,
      String? description,
      String? secret,
      String? pin,
      int? defaultBitRate,
      int? defaultExpectedLoss,
      bool? isPrivate,
      bool? audioLevelExt,
      bool? audioLevelEvent,
      int? audioActivePackets,
      int? audioLevelAverage,
      List<String>? allowed,
      bool? record,
      String? recordFile,
      String? recordDir,
      String? defaultPreBuffering,
      String? allowRtpParticipants,
      int? samplingRate,
      List<String>? groups,
      bool? spatialAudio}) async {
    var payload = {
      "request": "create",
      "room": roomId,
      "permanent": permanent,
      "description": description,
      "secret": secret,
      "pin": pin,
      "default_bitrate": defaultBitRate,
      "default_expectedloss": defaultExpectedLoss,
      "is_private": isPrivate,
      "allowed": allowed,
      "sampling_rate": samplingRate,
      "spatial_audio": spatialAudio,
      "audiolevel_ext": audioLevelExt,
      "audiolevel_event": audioLevelEvent,
      "audio_active_packets": audioActivePackets,
      "audio_level_average": audioLevelAverage,
      "default_prebuffering": defaultPreBuffering,
      "record": record,
      "record_file": recordFile,
      "record_dir": recordDir,
      "allow_rtp_participants": allowRtpParticipants,
      "groups": groups
    }..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return AudioRoomCreatedResponse.fromJson(response.plugindata?.data);
  }

  ///Once a room has been created, you can still edit some (but not all) of its properties using the edit request. This allows you to modify the room description, secret, pin and whether it's private or not: you won't be able to modify other more static properties, like the room ID, the sampling rate, the extensions-related stuff and so on. If you're interested in changing the ACL, instead, check the allowed message.<br><br>
  ///[roomId] : unique numeric ID of the room to edit<br>
  ///[secret] : room secret, mandatory if configured<br>
  ///[newDescription] : new pretty name of the room, optional<br>
  ///[newSecret] : new password required to edit/destroy the room, optional<br>
  ///[newPin] : new password required to join the room, optional<br>
  ///[newIsPrivate] : true|false, whether the room should appear in a list request<br>
  ///[permanent] : true|false, whether the room should be also removed from the config file, default=false
  ///
  Future<dynamic> editRoom(dynamic roomId, {String? secret, String? newDescription, String? newSecret, String? newPin, bool? newIsPrivate, bool? permanent}) async {
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
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return AudioRoomCreatedResponse.fromJson(response.plugindata?.data);
  }

  /// you use a join request to join an audio room, and wait for the joined event; this event will also include a list of the other participants, if any;<br><br>
  ///[roomId] : numeric ID of the room to join<br>
  ///[id] : unique ID to assign to the participant; optional, assigned by the plugin if missing<br>
  ///[group] : "group to assign to this participant (for forwarding purposes only; optional, mandatory if enabled in the room)<br>
  ///[pin] : "password required to join the room, if any; optional<br>
  ///[display] : "display name to have in the room; optional<br>
  ///[token] : "invitation token, in case the room has an ACL; optional<br>
  ///[muted] : true|false, whether to start unmuted or muted<br>
  ///[codec] : "codec to use, among opus (default), pcma (A-Law) or pcmu (mu-Law)<br>
  ///[preBuffer] : number of packets to buffer before decoding this participant (default=room value, or DEFAULT_PREBUFFERING)<br>
  ///[bitrate] : bitrate to use for the Opus stream in bps; optional, default=0 (libopus decides)<br>
  ///[quality] : 0-10, Opus-related complexity to use, the higher the value, the better the quality (but more CPU); optional, default is 4<br>
  ///[expectedLoss] : 0-20, a percentage of the expected loss (capped at 20%), only needed in case FEC is used; optional, default is 0 (FEC disabled even when negotiated) or the room default<br>
  ///[volume] : percent value, <100 reduces volume, >100 increases volume; optional, default is 100 (no volume change)<br>
  ///[spatialPosition] : in case spatial audio is enabled for the room, panning of this participant (0=left, 50=center, 100=right)<br>
  ///[secret] : "room management password; optional, if provided the user is an admin and can't be globally muted with mute_room<br>
  ///[audioLevelAverage] : "if provided, overrides the room audioLevelAverage for this user; optional<br>
  ///[audioActivePackets] : "if provided, overrides the room audioActivePackets for this user; optional<br>
  ///[record] : true|false, whether to record this user's contribution to a .mjr file (mixer not involved)<br>
  ///[filename] : "basename of the file to record to, -audio.mjr will be added by the plugin<br>
  ///
  Future<void> joinRoom(dynamic roomId,
      {dynamic id,
      String? group,
      String? pin,
      int? expectedLoss,
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
      "expected_loss": expectedLoss,
      "quality": quality,
      "volume": volume,
      "spatial_position": spatialPosition,
      "secret": secret,
      "audio_level_average": audioLevelAverage,
      "audioActivePackets": audioActivePackets,
      "record": record,
      "filename": filename
    }..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// [configure]
  ///
  /// muted instructs the plugin to mute or unmute the participant; quality changes the complexity of the Opus encoder for the participant; record can be used to record this participant's contribution to a Janus .mjr file, and filename to provide a basename for the path to save the file to (notice that this is different from the recording of a whole room: this feature only records the packets this user is sending, and is not related to the mixer stuff). A successful request will result in a ok event:<br><br>
  ///[muted] : true|false, whether to unmute or mute<br>
  ///[display] : new display name to have in the room"<br>
  ///[preBuffer] : new number of packets to buffer before decoding this participant (see "join" for more info)<br>
  ///[bitrate] : new bitrate to use for the Opus stream (see "join" for more info)<br>
  ///[quality] : new Opus-related complexity to use (see "join" for more info)<br>
  ///[expectedLoss] : new value for the expected loss (see "join" for more info)<br>
  ///[volume] : new volume percent value (see "join" for more info)<br>
  ///[spatialPosition] : in case spatial audio is enabled for the room, new panning of this participant (0=left, 50=center, 100=right)<br>
  ///[record] : true|false, whether to record this user's contribution to a .mjr file (mixer not involved)<br>
  ///[filename] : basename of the file to record to, -audio.mjr will be added by the plugin<br>
  ///[group] : new group to assign to this participant, if enabled in the room (for forwarding purposes)<br>
  ///[offer]: provide your own webrtc offer by default sends with audiosendrecv only
  Future<void> configure(
      {bool? muted,
      int? bitrate,
      String? display,
      int? preBuffer,
      int? quality,
      int? volume,
      int? spatialPosition,
      bool? record,
      String? filename,
      String? group,
      RTCSessionDescription? offer}) async {
    var payload = {
      "request": "configure",
      "muted": muted,
      "display": display,
      "bitrate": bitrate,
      "prebuffer": preBuffer,
      "quality": quality,
      "volume": volume,
      "spatial_position": spatialPosition,
      "record": record,
      "filename": filename,
      "group": group
    }..removeWhere((key, value) => value == null);
    if (offer == null) {
      offer = await this.createOffer(videoRecv: false, audioRecv: true);
    }
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
  Future<dynamic> muteParticipant(dynamic roomId, int participantId, bool mute, {String? secret}) async {
    var payload = {"request": mute ? 'mute' : 'unmute', "secret": secret, "room": roomId, "id": participantId}..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response.plugindata?.data;
  }

  /// [stopRtpForward]
  ///
  /// To stop a previously created RTP forwarder.<br>
  /// [roomId] unique numeric ID of the room to stop the forwarder from.<br>
  /// [streamId] unique numeric ID of the RTP forwarder.<br>
  Future<RtpForwardStopped> stopRtpForward(dynamic roomId, int streamId) async {
    var payload = {"request": "stop_rtp_forward", "room": roomId, "stream_id": streamId};
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return RtpForwardStopped.fromJson(response.plugindata?.data);
  }

  /// [kickParticipant]
  ///
  /// If you're the administrator of a room (that is, you created it and have access to the secret) you can kick out individual participant.
  /// [roomId] unique numeric ID of the room to stop the forwarder from.<br>
  /// [participantId] unique numeric ID of the participant.<br>
  /// [secret] admin secret should be provided if configured.<br>
  Future<dynamic> kickParticipant(dynamic roomId, int participantId, {String? secret}) async {
    var payload = {"request": "kick", "secret": secret, "room": roomId, "id": participantId}..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response.plugindata?.data;
  }

  /// [rtpForward]
  ///
  /// You can add a new RTP forwarder for an existing room using the rtp_forward request.<br>
  /// [roomId] unique numeric ID of the room to add the forwarder to.<br>
  /// [group] to forward, if enabled in the room (forwards full mix if missing).<br>
  /// [host] address to forward the RTP packets to.<br>
  /// [ssrc] to use to use when streaming (optional: stream_id used if missing).<br>
  /// [codec] opus (default), pcma (A-Law) or pcmu (mu-Law).<br>
  /// [hostFamily] ipv4|ipv6, if we need to resolve the host address to an IP; by default, whatever we get.<br>
  /// [port] to forward the RTP packets to.<br>
  /// [srtpSuite] length of authentication tag (32 or 80); optional. <br>
  /// [alwaysOn] true|false, whether silence should be forwarded when the room is empty.<br>
  /// [srtpCrypto] key to use as crypto (base64 encoded key as in SDES); optional.<br>
  /// [adminKey] key to use if adminKey is set for rtp forward as well.<br>
  Future<RtpForwarderCreated> rtpForward(dynamic roomId, String host, int port,
      {String? group, String? adminKey, String? ssrc, String? codec, String? ptype, int? srtpSuite, bool? alwaysOn, String? hostFamily, String? srtpCrypto}) async {
    var payload = {
      "request": "rtp_forward",
      "room": roomId,
      "admin_key": adminKey,
      "group": group,
      "ssrc": ssrc,
      "codec": codec,
      "ptype": ptype,
      "host": host,
      "host_family": hostFamily,
      "port": port,
      "srtp_suite": srtpSuite,
      "srtp_crypto": srtpCrypto,
      "always_on": alwaysOn
    }..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return RtpForwarderCreated.fromJson(response.plugindata?.data);
  }

  /// [listParticipants]
  ///
  /// To get a list of the participants in a specific room of [roomId]
  ///
  Future<List<AudioBridgeParticipants>> listParticipants(dynamic roomId) async {
    var payload = {
      "request": "listparticipants",
      "room": roomId,
    };
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return (response.plugindata?.data['participants'] as List<dynamic>).map((e) => AudioBridgeParticipants.fromJson(e)).toList();
  }

  bool _onCreated = false;

  Future<void> hangup() async {
    await super.hangup();
    await this.send(data: {"request": "leave"});
  }

  @override
  void onCreate() {
    super.onCreate();
    if (_onCreated) {
      return;
    }
    _onCreated = true;

    messages?.listen((event) {
      TypedEvent<JanusEvent> typedEvent = TypedEvent<JanusEvent>(event: JanusEvent.fromJson(event.event), jsep: event.jsep);
      var data = typedEvent.event.plugindata?.data;
      if (data == null) return;
      if (data["audiobridge"] == "joined") {
        typedEvent.event.plugindata?.data = AudioBridgeJoinedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["audiobridge"] == "event") {
        if (data["participants"] != null) {
          typedEvent.event.plugindata?.data = AudioBridgeNewParticipantsEvent.fromJson(data);
          _typedMessagesSink?.add(typedEvent);
        } else if (data["result"] == "ok") {
          typedEvent.event.plugindata?.data = AudioBridgeConfiguredEvent.fromJson(data);
          _typedMessagesSink?.add(typedEvent);
        } else if (data["leaving"] != null) {
          typedEvent.event.plugindata?.data = AudioBridgeLeavingEvent.fromJson(data);
          _typedMessagesSink?.add(typedEvent);
        } else if (data['error_code'] != null || data['result']?['code'] != null) {
          _typedMessagesSink?.addError(JanusError.fromMap(data));
        }
      } else if (data["audiobridge"] == "talking" || data["audiobridge"] == "stopped-talking") {
        typedEvent.event.plugindata?.data = AudioBridgeTalkingEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["audiobridge"] == "destroyed") {
        typedEvent.event.plugindata?.data = AudioBridgeDestroyedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['audiobridge'] == 'event' && (data['error_code'] != null || data['result']?['code'] != null)) {
        _typedMessagesSink?.addError(JanusError.fromMap(data));
      }
    });
  }
}
