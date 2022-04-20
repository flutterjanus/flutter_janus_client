part of janus_client;

class JanusVideoRoomPlugin extends JanusPlugin {
  JanusVideoRoomPlugin({handleId, context, transport, session})
      : super(
            context: context,
            handleId: handleId,
            plugin: JanusPlugins.VIDEO_ROOM,
            session: session,
            transport: transport);

  ///  This allows you to modify the room description, secret, pin and whether it's private or not:
  ///  you won't be able to modify other more static properties, like the room ID, the sampling rate,
  ///  the extensions-related stuff and so on
  Future<dynamic> editRoom(dynamic roomId,
      {String? secret,
      String? newDescription,
      String? newSecret,
      String? newPin,
      String? newIsPrivate,
      String? newRequirePvtId,
      String? newBitrate,
      String? newFirFreq,
      int? newPublisher,
      bool? newLockRecord,
      Map? extras,
      bool? permanent}) async {
    var payload = {
      "request": "edit",
      "room": roomId,
      ...?extras,
      if (secret != null) "secret": secret,
      if (newDescription != null) "new_description": newDescription,
      if (newSecret != null) "new_secret": newSecret,
      if (newPin != null) "new_pin": newPin,
      if (newIsPrivate != null) "new_is_private": newIsPrivate,
      if (newRequirePvtId != null) "new_require_pvtid": newRequirePvtId,
      if (newBitrate != null) "new_bitrate": newBitrate,
      if (newFirFreq != null) "new_fir_freq": newFirFreq,
      if (newPublisher != null) "new_publishers": newPublisher,
      if (newLockRecord != null) "new_lock_record": newLockRecord,
      if (permanent != null) "permanent": permanent
    };
    _handleRoomIdTypeDifference(payload);
    return (await this.send(data: payload));
  }

  /// Used to destroy an existing video room, whether created dynamically or statically
  Future<dynamic> destroyRoom(dynamic roomId,
      {String? secret, bool? permanent}) async {
    var payload = {
      "request": "destroy",
      "room": roomId,
      if (secret != null) "secret": secret,
      if (permanent != null) "permanent": permanent
    };
    _handleRoomIdTypeDifference(payload);
    return (await this.send(data: payload));
  }

  ///  Used to create a new video room
  Future<dynamic> createRoom(dynamic roomId,
      {bool permanent = false,
      String? pin,
      Map<String, dynamic>? extras,
      List<String>? allowed,
      String? isPrivate,
      String description = '',
      String? secret}) async {
    var payload = {
      "request": "create",
      "room": roomId,
      "permanent": permanent,
      "description": description,
      ...?extras
    };
    if (allowed != null) payload["allowed"] = allowed;
    if (isPrivate != null) payload["is_private"] = isPrivate;
    if (secret != null) payload['secret'] = secret;
    if (pin != null) payload['pin'] = pin;
    _handleRoomIdTypeDifference(payload);
    return (await this.send(data: payload));
  }

  /// get list of participants in a existing video room
  Future<VideoRoomListParticipantsResponse?> getRoomParticipants(
      dynamic roomId) async {
    var payload = {"request": "listparticipants", "room": roomId};
    Map data = await this.send(data: payload);
    _handleRoomIdTypeDifference(payload);
    return _getPluginDataFromPayload<VideoRoomListParticipantsResponse>(
        data, VideoRoomListParticipantsResponse.fromJson);
  }

  // prevent duplication
  T? _getPluginDataFromPayload<T>(dynamic data, T Function(dynamic) fromJson) {
    if (data.containsKey('janus') &&
        data['janus'] == 'success' &&
        data.containsKey('plugindata')) {
      var dat = data['plugindata']['data'];
      return dat;
    } else {
      return null;
    }
  }

  /// get list of all rooms
  Future<VideoRoomListResponse?> getRooms() async {
    var payload = {"request": "list"};
    Map data = await this.send(data: payload);
    return _getPluginDataFromPayload<VideoRoomListResponse>(
        data, VideoRoomListResponse.fromJson);
  }

  /// joins the [JanusVideoRoom] as a media publisher on provided [roomId] with its name as [displayName] and optionally can provide your own [id].
  Future<void> joinPublisher(dynamic roomId,
      {String? pin, int? id, String? token, String? displayName}) async {
    var payload = {
      "request": "join",
      "ptype": "publisher",
      "room": roomId,
      "pin": pin,
      "id": id,
      "display": displayName,
      "token": token,
    }..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    await this.send(data: payload);
  }

  Future<void> subscribeToStreams(List<PublisherStream> streams) async {
    if (streams.length > 0) {
      var payload = {
        'request': "subscribe",
        'streams': streams.map((e) => e.toMap()).toList()
      };
      await this.send(data: payload);
    }
  }

  /// joins the [JanusVideoRoom] as a media publisher on provided [roomId] with its name as [displayName] and optionally can provide your own [id].
  Future<
      Future<void> Function(
          {String? audioRecv,
          String? audioSend,
          String? videoRecv,
          String? videoSend})> joinSubscriber(
    dynamic roomId, {
    List<PublisherStream>? streams,
    int? privateId,
    int? feedId,
    String? pin,
    String? token,
  }) async {
    Future<void> start(
        {audioRecv = true,
        audioSend = false,
        videoRecv = true,
        videoSend = false}) async {
      var payload = {"request": "start", 'room': roomId};
      RTCSessionDescription? offer = await this.createNullableAnswer(
          audioRecv: audioRecv,
          audioSend: audioSend,
          videoRecv: videoRecv,
          videoSend: videoSend);
      if (offer != null) await this.send(data: payload, jsep: offer);
    }

    var payload = {
      "request": "join",
      "room": roomId,
      "ptype": "subscriber",
      "pin": pin,
      "token": token,
      "feed": feedId,
      "private_id": privateId,
      "streams": streams?.map((e) => e.toMap()).toList(),
    }..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    await this.send(data: payload);
    return start;
  }

  /// sends the publish request to [JanusVideoRoom]. It should be called once [VideoRoomJoinedEvent] is received from server.
  Future<void> publishMedia(
      {String? audioCodec,
      String? videCodec,
      int? bitrate,
      bool? record,
      String? filename,
      String? newDisplayName,
      int? audioLevelAverage,
      int? audioActivePackets,
      List<Map<String, String>>? descriptions,
      RTCSessionDescription? offer}) async {
    var payload = {
      "request": "publish",
      "audiocodec": audioCodec,
      "videocodec": videCodec,
      "bitrate": bitrate,
      "record": record,
      "filename": filename,
      "display": newDisplayName,
      "audio_level_average": audioLevelAverage,
      "audio_active_packets": audioActivePackets,
      "descriptions": descriptions
    }..removeWhere((key, value) => value == null);
    if (offer == null) {
      offer = await this.createOffer(
          audioRecv: false, audioSend: true, videoRecv: false, videoSend: true);
    }
    await this.send(data: payload, jsep: offer);
  }

  /// sends hangup request on current active [JanusVideoRoomPlugin] to tear off active PeerConnection in-effect leaving the room.
  Future<void> hangup() async {
    await super.hangup();
    await this.send(data: {"request": "leave"});
  }

  bool _onCreated = false;

  @override
  void onCreate() {
    if (!_onCreated) {
      _onCreated = true;
      messages?.listen((event) {
        TypedEvent<JanusEvent> typedEvent = TypedEvent<JanusEvent>(
            event: JanusEvent.fromJson(event.event), jsep: event.jsep);
        if (typedEvent.event.plugindata?.data['videoroom'] == 'joined') {
          typedEvent.event.plugindata?.data =
              VideoRoomJoinedEvent.fromJson(typedEvent.event.plugindata?.data);
          _typedMessagesSink?.add(typedEvent);
        } else if (typedEvent.event.plugindata?.data['videoroom'] == 'event' &&
            typedEvent.event.plugindata?.data['configured'] == "ok") {
          typedEvent.event.plugindata?.data =
              VideoRoomConfigured.fromJson(typedEvent.event.plugindata?.data);
          _typedMessagesSink?.add(typedEvent);
        } else if (typedEvent.event.plugindata?.data['videoroom'] == 'event' &&
            typedEvent.event.plugindata?.data['publishers'] != null) {
          typedEvent.event.plugindata?.data =
              VideoRoomNewPublisherEvent.fromJson(
                  typedEvent.event.plugindata?.data);
          _typedMessagesSink?.add(typedEvent);
        } else if (typedEvent.event.plugindata?.data['videoroom'] == 'event' &&
            typedEvent.event.plugindata?.data['leaving'] != null &&
            typedEvent.event.plugindata?.data['leaving'].runtimeType == int) {
          typedEvent.event.plugindata?.data =
              VideoRoomLeavingEvent.fromJson(typedEvent.event.plugindata?.data);
          _typedMessagesSink?.add(typedEvent);
        } else if (typedEvent.event.plugindata?.data['videoroom'] ==
                'attached' ||
            typedEvent.event.plugindata?.data['streams'] != null) {
          typedEvent.event.plugindata?.data = VideoRoomAttachedEvent.fromJson(
              typedEvent.event.plugindata?.data);
          _typedMessagesSink?.add(typedEvent);
        } else if (typedEvent.event.plugindata?.data['videoroom'] == 'event' &&
            (typedEvent.event.plugindata?.data['error_code'] != null ||
                typedEvent.event.plugindata?.data?['result']?['code'] !=
                    null)) {
          _typedMessagesSink
              ?.addError(JanusError.fromMap(typedEvent.event.plugindata?.data));
        }
      });
    }
  }
}
