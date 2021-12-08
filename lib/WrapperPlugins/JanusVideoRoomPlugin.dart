import 'package:janus_client/JanusClient.dart';

class JanusVideoRoomPlugin extends JanusPlugin {
  JanusVideoRoomPlugin({handleId, context, transport, session, plugin}) : super(context: context, handleId: handleId, plugin: plugin, session: session, transport: transport);

  /// You can check whether a room exists using the exists
  Future<dynamic> exists(int roomId) async {
    var payload = {"request": "exists", "room": roomId};
    return (await this.send(data: payload));
  }

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
      bool? permanent}) async {
    var payload = {
      "request": "edit",
      "room": roomId,
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
    return _getPluginDataFromPayload<VideoRoomListParticipantsResponse>(data,VideoRoomListParticipantsResponse.fromJson);
  }
  // prevent duplication
  T? _getPluginDataFromPayload<T>(dynamic data,T Function(dynamic) fromJson){
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
    return _getPluginDataFromPayload<VideoRoomListResponse>(data,VideoRoomListResponse.fromJson);
  }

  Future<dynamic> joinPublisher(int roomId, {int? id, String? token, String? displayName}) async {
    var payload = {"request": "join", "ptype": "publisher", "room": roomId, if (id != null) "id": id, if (displayName != null) "display": displayName, if (token != null) "token": token};

  }
}
