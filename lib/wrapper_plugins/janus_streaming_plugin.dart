part of janus_client;

class JanusStreamingPlugin extends JanusPlugin {
  JanusStreamingPlugin({handleId, context, transport, session})
      : super(context: context, handleId: handleId, plugin: JanusPlugins.STREAMING, session: session, transport: transport);

  /// Get list of all streaming mount-point available on server
  Future<List<StreamingMountPoint>> listStreams() async {
    var payload = {"request": "list"};
    var response = await this.send(data: payload);
    if (response['janus'] == 'success' && response['plugindata'] != null && response['plugindata']['data'] != null && response['plugindata']['data']['list'] != null) {
      return (response['plugindata']['data']['list'] as List<dynamic>).map((e) => StreamingMountPoint.fromJson(e)).toList();
    }
    return [];
  }

  /// Get verbose info of a specific mount-point
  Future<StreamingMountPointInfo?> getStreamInfo(int id, {String? secret}) async {
    var payload = {"request": "info", "id": id, if (secret != null) "secret": secret};
    var response = await this.send(data: payload);
    if (response['info'] != null) {
      return StreamingMountPointInfo.fromJson(response['info']);
    }
    return null;
  }

  /// Create a new streaming Mount-point
  /// type = rtp|live|ondemand|rtsp
  ///        rtp = stream originated by an external tool (e.g., gstreamer or
  ///              ffmpeg) and sent to the plugin via RTP
  ///        live = local file streamed live to multiple viewers
  ///               (multiple viewers = same streaming context)
  ///        ondemand = local file streamed on-demand to a single listener
  ///                   (multiple viewers = different streaming contexts)
  ///        rtsp = stream originated by an external RTSP feed (only
  ///               available if libcurl support was compiled)
  Future<StreamingMount?> createStream(String type,
      {String? name,
      String? description,
      String? metadata,
      int? id,
      String? pin,
      List<CreateMediaItem>? media,
      String? secret,
      bool? isPrivate,
      bool? permanent,
      String? adminKey}) async {
    var payload = {
      "request": "create",
      "type": type,
      if (adminKey != null) "admin_key": adminKey,
      if (id != null) "id": id,
      if (name != null) "name": name,
      if (description != null) "description": description,
      if (metadata != null) "metadata": metadata,
      if (secret != null) "secret": secret,
      if (pin != null) "pin": pin,
      if (isPrivate != null) "is_private": isPrivate,
      if (permanent != null) "permanent": permanent,
      if (media != null) "media": media,
    };
    var response = await this.send(data: payload);
    if (response['streaming'] == 'created') {
      return StreamingMount.fromJson(response);
    }
    return null;
  }

  /// edit existing streaming mount-point
  Future<StreamingMountEdited?> editStream(int id,
      {String? secret, String? description, String? metadata, String? newSecret, bool? newIsPrivate, bool? permanent, String? newPin}) async {
    var payload = {
      "request": "edit",
      "id": id,
      if (secret != null) "secret": secret,
      if (description != null) "new_description": description,
      if (metadata != null) "new_metadata": metadata,
      if (newSecret != null) "new_secret": newSecret,
      if (newPin != null) "new_pin": newPin,
      if (newIsPrivate != null) "new_is_private": newIsPrivate,
      if (permanent != null) "permanent": permanent
    };
    var response = await this.send(data: payload);
    if (response['streaming'] == 'edited') {
      return StreamingMountEdited.fromJson(response);
    }
    return null;
  }

  /// destroy existing streaming mount-point
  /// setting permanent true will delete from config files as well.
  ///
  Future<bool> destroyStream(int id, {String? secret, bool? permanent}) async {
    var payload = {"request": "destroy", "id": id, if (secret != null) "secret": secret, if (permanent != null) "permanent": permanent};
    var response = await this.send(data: payload);
    if (response['streaming'] == 'destroyed') {
      return true;
    }
    return false;
  }

  Future<void> watchStream(
    int id, {
    List<CreateMediaItem>? media,
    String? pin,
    @Deprecated('It is legacy option,you should use media for fine grade control') bool? offerAudio,
    @Deprecated('It is legacy option,you should use media for fine grade control') bool? offerVideo,
    @Deprecated('It is legacy option,you should use media for fine grade control') bool? offerData,
  }) async {
    var payload = {
      "request": "watch",
      "id": id,
      if (pin != null) "pin": pin,
      if (media != null) "media": media,
      if (offerAudio != null) "offer_audio": true,
      if (offerVideo != null) "offer_video": true,
      if (offerData != null) "offer_data": offerData
    };
    await this.send(data: payload);
  }

  /// call this method once watch request is successfully completed
  Future<void> startStream() async {
    if (webRTCHandle?.peerConnection?.iceConnectionState == RTCIceConnectionState.RTCIceConnectionStateConnected) {
      await send(data: {"request": "start"});
    } else {
      RTCSessionDescription answer = await createAnswer();
      await send(data: {"request": "start"}, jsep: answer);
    }
  }

  /// temporarily stop media delivery
  Future<void> pauseStream() async {
    await send(data: {"request": "pause"});
  }

  /// stop the media flow entirely
  Future<void> stopStream() async {
    await send(data: {"request": "stop"});
  }

  /// switch to different streaming mount point
  Future<void> switchStream(int id) async {
    await send(data: {"request": "switch", "id": id});
  }

  bool _onCreated = false;

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
      if (data["streaming"] == "event" && data["result"] != null && data["result"]['status'] == 'preparing') {
        typedEvent.event.plugindata?.data = StreamingPluginPreparingEvent();
        _typedMessagesSink?.add(typedEvent);
      } else if (data["streaming"] == "event" && data["result"] != null && data["result"]['status'] == 'stopping') {
        typedEvent.event.plugindata?.data = StreamingPluginStoppingEvent();
        _typedMessagesSink?.add(typedEvent);
      } else if (data['streaming'] == 'event' && (data['error_code'] != null || data['result']?['code'] != null)) {
        _typedMessagesSink?.addError(JanusError.fromMap(data));
      }
    });
  }
}
