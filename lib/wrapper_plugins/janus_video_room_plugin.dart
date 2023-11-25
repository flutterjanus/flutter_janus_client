part of janus_client;

enum ConfigureStreamQuality { LOW, MEDIUM, HIGH }

class ConfigureStream {
  String? mid;
  bool? send;
  int? fallback;
  int? audio_level_average;
  int? audio_active_packets;
  int? min_delay;
  int? max_delay;
  ConfigureStreamQuality? substream;
  ConfigureStreamQuality? temporal;
  ConfigureStreamQuality? spatial_layer;
  ConfigureStreamQuality? temporal_layer;

  ConfigureStream({
    this.mid,
    this.substream,
    this.temporal,
    this.spatial_layer,
    this.temporal_layer,
    this.send,
    this.fallback,
    this.audio_level_average,
    this.audio_active_packets,
    this.min_delay,
    this.max_delay,
  });

  Map<String, dynamic> toMap() {
    return {
      'mid': mid,
      'send': send,
      'substream': substream?.index,
      'temporal': temporal?.index,
      'spatial_layer': spatial_layer?.index,
      'temporal_layer': temporal_layer?.index,
      'fallback': fallback,
      'audio_level_average': audio_level_average,
      'audio_active_packets': audio_active_packets,
      'min_delay': min_delay,
      'max_delay': max_delay,
    }..removeWhere((key, value) => value == null);
  }

  factory ConfigureStream.fromMap(Map<String, dynamic> map) {
    return ConfigureStream(
      mid: map['mid'],
      substream: map['substream'] != null ? ConfigureStreamQuality.values[map['substream']] : null,
      temporal: map['temporal'] != null ? ConfigureStreamQuality.values[map['temporal']] : null,
      spatial_layer: map['spatial_layer'] != null ? ConfigureStreamQuality.values[map['spatial_layer']] : null,
      temporal_layer: map['temporal_layer'] != null ? ConfigureStreamQuality.values[map['temporal_layer']] : null,
      send: map['send'],
      fallback: map['fallback']?.toInt(),
      audio_level_average: map['audio_level_average']?.toInt(),
      audio_active_packets: map['audio_active_packets']?.toInt(),
      min_delay: map['min_delay']?.toInt(),
      max_delay: map['max_delay']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ConfigureStream.fromJson(String source) => ConfigureStream.fromMap(json.decode(source));

  @override
  String toString() {
    return '''ConfigureStream(mid: $mid, 
    substream: $substream,
    temporal: $temporal,
    spatial_layer: $spatial_layer,
    temporal_layer: $temporal_layer,
    send: $send, fallback: $fallback, audio_level_average: $audio_level_average, audio_active_packets: $audio_active_packets, min_delay: $min_delay, max_delay: $max_delay)''';
  }
}

class JanusVideoRoomPlugin extends JanusPlugin {
  JanusVideoRoomPlugin({handleId, context, transport, session})
      : super(context: context, handleId: handleId, plugin: JanusPlugins.VIDEO_ROOM, session: session, transport: transport);

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
  Future<dynamic> destroyRoom(dynamic roomId, {String? secret, bool? permanent}) async {
    var payload = {"request": "destroy", "room": roomId, if (secret != null) "secret": secret, if (permanent != null) "permanent": permanent};
    _handleRoomIdTypeDifference(payload);
    return (await this.send(data: payload));
  }

  ///  Used to create a new video room
  Future<dynamic> createRoom(dynamic roomId,
      {bool permanent = false, String? pin, Map<String, dynamic>? extras, List<String>? allowed, String? isPrivate, String description = '', String? secret}) async {
    var payload = {"request": "create", "room": roomId, "permanent": permanent, "description": description, ...?extras};
    if (allowed != null) payload["allowed"] = allowed;
    if (isPrivate != null) payload["is_private"] = isPrivate;
    if (secret != null) payload['secret'] = secret;
    if (pin != null) payload['pin'] = pin;
    _handleRoomIdTypeDifference(payload);
    return (await this.send(data: payload));
  }

  /// get list of participants in a existing video room
  Future<VideoRoomListParticipantsResponse?> getRoomParticipants(dynamic roomId) async {
    var payload = {"request": "listparticipants", "room": roomId};
    Map data = await this.send(data: payload);
    _handleRoomIdTypeDifference(payload);
    return _getPluginDataFromPayload<VideoRoomListParticipantsResponse>(data, VideoRoomListParticipantsResponse.fromJson);
  }

  // prevent duplication
  T? _getPluginDataFromPayload<T>(dynamic data, T Function(dynamic) fromJson) {
    if (data.containsKey('janus') && data['janus'] == 'success' && data.containsKey('plugindata')) {
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
    return _getPluginDataFromPayload<VideoRoomListResponse>(data, VideoRoomListResponse.fromJson);
  }

  /// joins the [JanusVideoRoom] as a media publisher on provided [roomId] with its name as [displayName] and optionally can provide your own [id].
  Future<void> joinPublisher(dynamic roomId, {String? pin, int? id, String? token, String? displayName}) async {
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

  Future<void> subscribeToStreams(List<PublisherStream> streams, {RTCSessionDescription? offer}) async {
    if (streams.length > 0) {
      var payload = {'request': "subscribe", 'streams': streams.map((e) => e.toMap()..removeWhere((key, value) => value == null)).toList()};
      await this.send(data: payload, jsep: offer);
    }
  }

  Future<void> update({List<SubscriberUpdateStream>? subscribe, List<SubscriberUpdateStream>? unsubscribe}) async {
    if (subscribe?.isEmpty == true && unsubscribe?.isEmpty == true) {
      return;
    }
    Map<String, dynamic> payload = {
      'request': "update",
    };
    if (subscribe?.isNotEmpty == true) {
      payload['subscribe'] = subscribe?.map((e) => e.toMap()..removeWhere((key, value) => value == null)).toList();
    }
    if (unsubscribe?.isNotEmpty == true) {
      payload['unsubscribe'] = unsubscribe?.map((e) => e.toMap()..removeWhere((key, value) => value == null)).toList();
    }
    await this.send(data: payload);
  }

  Future<void> start(dynamic roomId, {RTCSessionDescription? answer}) async {
    var payload = {"request": "start", 'room': roomId};
    if (answer == null) {
      answer = await this.createAnswer();
    }
    await this.send(data: payload, jsep: answer);
  }

  /// joins the [JanusVideoRoom] as a media publisher on provided [roomId] with its name as [displayName] and optionally can provide your own [id].
  Future<dynamic> joinSubscriber(
    dynamic roomId, {
    List<PublisherStream>? streams,
    int? privateId,
    int? feedId,
    String? pin,
    String? token,
  }) async {
    var payload = {
      "request": "join",
      "room": roomId,
      "ptype": "subscriber",
      "pin": pin,
      "token": token,
      "feed": feedId,
      "private_id": privateId,
      "streams": streams?.map((e) => e.toMap()..removeWhere((key, value) => value == null)).toList(),
    }..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    await this.send(data: payload);
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
      List<Map<String, String?>>? descriptions,
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
      offer = await this.createOffer(audioRecv: false, videoRecv: false);
    }
    await this.send(data: payload, jsep: offer);
  }

  Future<void> configure(
      {int? bitrate,
      bool? keyframe,
      bool? record,
      String? filename,
      String? display,
      dynamic audioActivePackets,
      int? audioLevelAverage,
      List<Map<String, String>>? descriptions,
      List<ConfigureStream>? streams,
      bool? restart,
      RTCSessionDescription? sessionDescription}) async {
    var payload = {
      "request": "configure",
      "bitrate": bitrate,
      "keyframe": keyframe,
      "record": record,
      "filename": filename,
      "display": display,
      "audio_active_packets": audioActivePackets,
      "audio_level_average": audioLevelAverage,
      "streams": streams?.map((e) => e.toMap()).toList(),
      "restart": restart,
      "descriptions": descriptions
    }..removeWhere((key, value) => value == null);
    await this.send(data: payload, jsep: sessionDescription);
  }

  Future<void> unsubscribe({List<UnsubscribeStreams>? streams}) async {
    var payload = {"request": "unsubscribe", "streams": streams?.map((e) => e.toMap()..removeWhere((key, value) => value == null)).toList()}
      ..removeWhere((key, value) => value == null);
    await this.send(data: payload);
  }

  /// sends unpublish request on current active [JanusVideoRoomPlugin] to tear off active PeerConnection in-effect leaving the room.
  Future<void> unpublish() async {
    await this.send(data: {"request": "unpublish"});
  }

  /// sends hangup request on current active [JanusVideoRoomPlugin] to tear off active PeerConnection in-effect leaving the room.
  Future<void> hangup() async {
    await super.hangup();
    await this.send(data: {"request": "leave"});
  }

  bool _onCreated = false;

  @override
  void onCreate() {
    if (_onCreated) {
      return;
    }
    _onCreated = true;
    messages?.listen((event) {
      TypedEvent<JanusEvent> typedEvent = TypedEvent<JanusEvent>(event: JanusEvent.fromJson(event.event), jsep: event.jsep);
      var data = typedEvent.event.plugindata?.data;
      if (data == null) return;
      if (data['videoroom'] == 'joined') {
        typedEvent.event.plugindata?.data = VideoRoomJoinedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videoroom'] == 'event' && data['unpublished'] != null && data['unpublished'] is int) {
        typedEvent.event.plugindata?.data = VideoRoomUnPublishedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videoroom'] == 'updated' && data['streams'] != null) {
        typedEvent.event.plugindata?.data = VideoRoomUpdatedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videoroom'] == 'event' && data['configured'] == "ok") {
        typedEvent.event.plugindata?.data = VideoRoomConfigured.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videoroom'] == 'event' && data['publishers'] != null) {
        typedEvent.event.plugindata?.data = VideoRoomNewPublisherEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videoroom'] == 'event' && data['leaving'] != null && data['leaving'].runtimeType == int) {
        typedEvent.event.plugindata?.data = VideoRoomLeavingEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videoroom'] == 'attached' || data['streams'] != null) {
        typedEvent.event.plugindata?.data = VideoRoomAttachedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videoroom'] == 'event' && (data['error_code'] != null || data['result']?['code'] != null)) {
        _typedMessagesSink?.addError(JanusError.fromMap(data));
      }
    });
  }
}
