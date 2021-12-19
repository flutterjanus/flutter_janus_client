import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/JanusClient.dart';
class JanusVideoRoomPlugin extends JanusPlugin {
  JanusVideoRoomPlugin({handleId, context, transport, session}) : super(context: context, handleId: handleId, plugin: JanusPlugins.VIDEO_ROOM, session: session, transport: transport);

  ///  This allows you to modify the room description, secret, pin and whether it's private or not:
  ///  you won't be able to modify other more static properties, like the room ID, the sampling rate,
  ///  the extensions-related stuff and so on
  Future<dynamic> editRoom(int roomId,
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
    return (await this.send(data: payload));
  }

  /// Used to destroy an existing video room, whether created dynamically or statically
  Future<dynamic> destroyRoom(int roomId, {String? secret, bool? permanent}) async {
    var payload = {"request": "destroy", "room": roomId, if (secret != null) "secret": secret, if (permanent != null) "permanent": permanent};
    return (await this.send(data: payload));
  }

  ///  Used to create a new video room
  Future<dynamic> createRoom(int roomId, {bool permanent = false, String? pin, Map<String, dynamic>? extras, List<String>? allowed, String? isPrivate, String description = '', String? secret}) async {
    var payload = {"request": "create", "room": roomId, "permanent": permanent, "description": description, ...?extras};
    if (allowed != null) payload["allowed"] = allowed;
    if (isPrivate != null) payload["is_private"] = isPrivate;
    if (secret != null) payload['secret'] = secret;
    if (pin != null) payload['pin'] = pin;
    return (await this.send(data: payload));
  }

  /// get list of participants in a existing video room
  Future<VideoRoomListParticipantsResponse?> getRoomParticipants(int roomId) async {
    var payload = {"request": "listparticipants", "room": roomId};
    Map data = await this.send(data: payload);
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

  Future<void> joinPublisher(int roomId, {int? id, String? token, String? displayName}) async {
    var payload = {
      "request": "join",
      "ptype": "publisher",
      "room": roomId,
      if (id != null) "id": id,
      if (displayName != null) "display": displayName,
      if (token != null) "token": token,
    };
    Map data = await this.send(data: payload);
  }

  Future<void> subscribeToStreams(List<PublisherStream> streams)async{
    if(streams.length>0){
      var payload = {'request': "subscribe", 'streams': streams.map((e) => e.toMap()).toList()};
      await this.send(data: payload);
    }
  }
  Future<Future<void> Function({String? audioRecv, String? audioSend, String? videoRecv, String? videoSend})> joinSubscriber(int roomId,
      {List<PublisherStream>? streams, int? privateId, int? feedId}) async {
    Future<void> start({audioRecv = true, audioSend = false, videoRecv = true, videoSend = false}) async {
      var payload = {"request": "start", 'room': roomId};
      RTCSessionDescription? offer = await this.createNullableAnswer(audioRecv: audioRecv, audioSend: audioSend, videoRecv: videoRecv, videoSend: videoSend);
      if (offer != null) await this.send(data: payload, jsep: offer);
    }

    var payload = {
      "request": "join",
      "room": roomId,
      "ptype": "subscriber",
      if (feedId != null) "feed": feedId,
      if (privateId != null) "private_id": privateId,
      if (streams != null) "streams": (streams).map((e) => e.toMap()).toList(),
    };
    Map data = await this.send(data: payload);
    return start;
  }

  Future<void> publishMedia(
      {String? audioCodec,
      String? videCodec,
      int? bitrate,
      bool? record,
      String? filename,
      String? newDisplayName,
      int? audioLevelAverage,
      int? audioActivePackets,
      List<Map<String, String>>? descriptions}) async {
    var payload = {
      "request": "publish",
      if (audioCodec != null) "audiocodec": audioCodec,
      if (videCodec != null) "videocodec": videCodec,
      if (bitrate != null) "bitrate": bitrate,
      if (record != null) "record": record,
      if (filename != null) "filename": filename,
      if (newDisplayName != null) "display": newDisplayName,
      if (audioLevelAverage != null) "audio_level_average": audioLevelAverage,
      if (audioActivePackets != null) "audio_active_packets": audioActivePackets,
      if (descriptions != null) "descriptions": descriptions
    };
    RTCSessionDescription offer = await this.createOffer(audioRecv: false, audioSend: true, videoRecv: false, videoSend: true);
    Map data = await this.send(data: payload, jsep: offer);
  }

  bool _onCreated = false;

  @override
  void onCreate() {
    if (!_onCreated) {
      _onCreated = true;
      messages?.listen((event) {
        TypedEvent<JanusEvent> typedEvent = TypedEvent<JanusEvent>(event: JanusEvent.fromJson(event.event), jsep: event.jsep);
         if (typedEvent.event.plugindata?.data['videoroom'] == 'joined') {
          typedEvent.event.plugindata?.data = VideoRoomJoinedEvent.fromJson(typedEvent.event.plugindata?.data);
          typedMessagesSink?.add(typedEvent);
        }
         else if (typedEvent.event.plugindata?.data['videoroom'] == 'event' && typedEvent.event.plugindata?.data['configured'] == "ok") {
           typedEvent.event.plugindata?.data = VideoRoomConfigured.fromJson(typedEvent.event.plugindata?.data);
           typedMessagesSink?.add(typedEvent);
         }
        else if (typedEvent.event.plugindata?.data['videoroom'] == 'event' && typedEvent.event.plugindata?.data['publishers'] != null) {
          typedEvent.event.plugindata?.data = VideoRoomNewPublisherEvent.fromJson(typedEvent.event.plugindata?.data);
          typedMessagesSink?.add(typedEvent);
        } else if (typedEvent.event.plugindata?.data['videoroom'] == 'event' && typedEvent.event.plugindata?.data['leaving'] != null) {
          typedEvent.event.plugindata?.data = VideoRoomLeavingEvent.fromJson(typedEvent.event.plugindata?.data);
          typedMessagesSink?.add(typedEvent);
        } else if (typedEvent.event.plugindata?.data['videoroom'] == 'attached' || typedEvent.event.plugindata?.data['streams'] != null) {
          typedEvent.event.plugindata?.data = VideoRoomAttachedEvent.fromJson(typedEvent.event.plugindata?.data);
          typedMessagesSink?.add(typedEvent);
        }
        // if (typedEvent.jsep != null) {
        //   typedEvent.jsep=event.jsep;
        //   typedMessagesSink?.add(typedEvent);
        // }
      });
    }
  }
}
