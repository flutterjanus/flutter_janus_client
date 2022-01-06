import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/JanusClient.dart';
import 'package:janus_client/interfaces/Streaming/Events/StreamingPluginPreparingEvent.dart';

class JanusStreamingPlugin extends JanusPlugin {
  JanusStreamingPlugin({handleId, context, transport, session}) : super(context: context, handleId: handleId, plugin: JanusPlugins.STREAMING, session: session, transport: transport);

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

  /// Create a new Streaming Mount-point
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
      {String? name, String? description, String? metadata, int? id, String? pin, List<CreateMediaItem>? media, String? secret, bool? is_private, bool? permanent, String? admin_key}) async {
    var payload = {
      "request": "create",
      "type": type,
      if (admin_key != null) "admin_key": admin_key,
      if (id != null) "id": id,
      if (name != null) "name": name,
      if (description != null) "description": description,
      if (metadata != null) "metadata": metadata,
      if (secret != null) "secret": secret,
      if (pin != null) "pin": pin,
      if (is_private != null) "is_private": is_private,
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
  Future<StreamingMountEdited?> editStream(int id, {String? secret, String? description, String? metadata, String? newSecret, bool? newIsPrivate, bool? permanent, String? newPin}) async {
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
    @Deprecated('It is legacy option,you should use media for fine grade control') bool? offer_audio,
    @Deprecated('It is legacy option,you should use media for fine grade control') bool? offer_video,
    @Deprecated('It is legacy option,you should use media for fine grade control') bool? offer_data,
  }) async {
    var payload = {
      "request": "watch",
      "id": id,
      if (pin != null) "pin": pin,
      if (media != null) "media": media,
      if (offer_audio != null) "offer_audio": true,
      if (offer_video != null) "offer_video": true,
      if (offer_data != null) "offer_data": offer_data
    };
    await this.send(data: payload);
  }
  /// start stream if watch request is successfully completed
  Future<void> startStream()async{
    if(webRTCHandle?.peerConnection?.iceConnectionState==RTCIceConnectionState.RTCIceConnectionStateConnected){
      await send(data: {"request": "start"});
    }
    else{
      RTCSessionDescription answer = await createAnswer();
      await send(data: {"request": "start"}, jsep: answer);
    }
  }
  /// temporarily stop media delivery
  Future<void> pauseStream()async{
    await send(data:   {
      "request" : "pause"
    });
  }
  /// stop the media flow entirely
  Future<void> stopStream()async{
    await send(data:   {
      "request" : "stop"
    });
  }
  /// switch to different streaming mount point
  Future<void> switchStream(int id)async{
    await send(data: {
    "request" : "switch",
    "id" :id
    });
  }

  bool _onCreated = false;

  @override
  void onCreate() {
    super.onCreate();
    if (!_onCreated) {
      _onCreated = true;
      messages?.listen((event) {
        TypedEvent<JanusEvent> typedEvent = TypedEvent<JanusEvent>(event: JanusEvent.fromJson(event.event), jsep: event.jsep);
        if (typedEvent.event.plugindata?.data["streaming"] == "event"
            &&
            typedEvent.event.plugindata?.data["result"]!=null
            &&
            typedEvent.event.plugindata?.data["result"]['status']=='preparing'
        ) {
          typedEvent.event.plugindata?.data = StreamingPluginPreparingEvent();
          typedMessagesSink?.add(typedEvent);
        }
        else if (typedEvent.event.plugindata?.data["streaming"] == "event"&&
            typedEvent.event.plugindata?.data["result"]!=null&&
            typedEvent.event.plugindata?.data["result"]['status']=='stopping'
        ) {
          typedEvent.event.plugindata?.data = StreamingPluginStoppingEvent();
          typedMessagesSink?.add(typedEvent);
        }
      });
    }
  }

}
