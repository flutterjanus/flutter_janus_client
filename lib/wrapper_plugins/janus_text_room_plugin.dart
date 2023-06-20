part of janus_client;

class JanusTextRoomPlugin extends JanusPlugin {
  JanusTextRoomPlugin({handleId, context, transport, session})
      : super(context: context, handleId: handleId, plugin: JanusPlugins.TEXT_ROOM, session: session, transport: transport);

  bool _setup = false;

  bool get setupDone => _setup;

  /// [setup]
  /// setup is a method to be called very early to negotiate open PeerConnection on which data channels can be created and further operations of text room can be performed.
  ///
  Future<void> setup() async {
    var body = {"request": "setup"};
    await this.send(data: body);
    this.messages?.listen((event) async {
      if (event.jsep != null) {
        await this.handleRemoteJsep(event.jsep);
        var body = {"request": "ack"};
        await this.initDataChannel();
        RTCSessionDescription answer = await this.createAnswer();
        await this.send(
          data: body,
          jsep: answer,
        );
      }
    });
    this._setup = true;
  }

  /// [joinRoom]
  ///
  /// you use a join request to join a Text Room, make sure to call [setup] before calling [joinRoom]<br><br>
  ///[roomId] : numeric ID of the room to join.<br>
  ///[username] : unique username to have in the room; mandatory. <br>
  ///[pin] : pin to join the room; mandatory if configured.<br>
  ///[display] : display name to have in the room; optional.<br>
  ///[token] : invitation token, in case the room has an ACL; optional.<br>
  ///[history] : true|false, whether to retrieve history messages when available (default=true).<br>
  ///
  Future<void> joinRoom(int roomId, String username, {String? pin, String? display, String? token, bool? history}) async {
    if (setupDone) {
      _context._logger.info('data channel is open, now trying to join');
      var register = {'textroom': "join", 'transaction': randomString(), 'room': roomId, 'username': username, 'display': display, "pin": pin, "token": token, "history": history}
        ..removeWhere((key, value) => value == null);
      _handleRoomIdTypeDifference(register);
      await this.sendData(stringify(register));
    } else {
      _context._logger.shout('method was called before calling setup(), hence aborting further operation.');
      throw "method was called before calling setup(), hence aborting further operation.";
    }
  }

  /// you use a leave request to leave already joined Text Room, make sure to call [setup] before calling [leaveRoom]<br><br>
  ///[roomId] : numeric ID of the room to join.<br>
  ///
  Future<void> leaveRoom(int roomId) async {
    if (setupDone) {
      _context._logger.fine('trying to leave room $roomId');
      var payload = {"textroom": "leave", "room": roomId};
      _handleRoomIdTypeDifference(payload);
      await this.sendData(stringify(payload));
    } else {
      _context._logger.shout('method was called before calling setup(), hence aborting further operation.');
      throw "method was called before calling setup(), hence aborting further operation.";
    }
  }

  ///[roomId] : numeric ID of the room to join.<br>
  ///[text] : content of the message to send, as a string.<br>
  ///[ack] : true|false, whether the sender wants an ack for the sent message(s); optional, true by default <br>.
  ///[to] : username to send the message to; optional, only needed in case of private messages. <br>
  ///[tos] : array of usernames to send the message to; optional, only needed in case of private messages. <br>
  Future<void> sendMessage(dynamic roomId, String text, {bool? ack, String? to, List<String>? tos}) async {
    if (setupDone) {
      var message = {'transaction': randomString(), "textroom": "message", "room": roomId, "text": text, "to": to, "tos": tos, "ack": ack}
        ..removeWhere((key, value) => value == null);
      _handleRoomIdTypeDifference(message);
      _context._logger.fine('sending text message to room:$roomId with payload:$message');
      await this.sendData(stringify(message));
    } else {
      _context._logger.shout('method was called before calling setup(), hence aborting further operation.');
      throw "method was called before calling setup(), hence aborting further operation.";
    }
  }

  Future<List<JanusTextRoom>?> listRooms() async {
    var payload = {
      "request": "list",
    };
    _handleRoomIdTypeDifference(payload);
    _context._logger.fine('list rooms invoked');
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return (response.plugindata?.data?['list'] as List<dynamic>?)?.map((e) => JanusTextRoom.fromJson(e)).toList();
  }

  Future<List<dynamic>?> listParticipants(dynamic roomId) async {
    var payload = {"request": "listparticipants", "room": roomId};
    _handleRoomIdTypeDifference(payload);
    _context._logger.fine('listParticipants invoked with roomId:$roomId');
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response.plugindata?.data?['participants'];
  }

  Future<bool?> exists(dynamic roomId) async {
    var payload = {"request": "exists", "room": roomId};
    _handleRoomIdTypeDifference(payload);
    _context._logger.fine('exists invoked with roomId:$roomId');
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response.plugindata?.data?['exists'];
  }

  /// If you're the administrator of a room (that is, you created it and have access to the secret) you can kick out individual participant.
  /// [roomId] unique numeric ID of the room to stop the forwarder from.<br>
  /// [username] username of the participant to kick.<br>
  /// [secret] admin secret should be provided if configured.<br>
  Future<dynamic> kickParticipant(dynamic roomId, String username, {String? secret}) async {
    var payload = {"request": "kick", "secret": secret, "room": roomId, "username": username}..removeWhere((key, value) => value == null);
    _handleRoomIdTypeDifference(payload);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response.plugindata?.data;
  }

  /// this can be used to destroy a room .<br>
  /// Notice that, in general, all users can create rooms. If you want to limit this functionality, you can configure an admin admin_key in the plugin settings. When configured, only "create" requests that include the correct admin_key value in an "admin_key" property will succeed, and will be rejected otherwise. Notice that you can optionally extend this functionality to RTP forwarding as well, in order to only allow trusted clients to use that feature.<br><br>
  ///[roomId] : unique numeric ID, optional, chosen by plugin if missing.<br>
  ///[permanent] : true|false, whether the room should be also removed from the config file; default=false.<br>
  ///[secret] : password required to edit/destroy the room, optional.<br>
  Future<dynamic> destroyRoom({int? roomId, String? secret, bool? permanent}) async {
    var payload = {
      "textroom": "destroy",
      "room": roomId,
      "secret": secret,
      "permanent": permanent,
    };
    _handleRoomIdTypeDifference(payload);
    _context._logger.fine('destroyRoom invoked with roomId:$roomId');
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response;
  }

  /// this can be used to create a new text room .<br>
  /// Notice that, in general, all users can create rooms. If you want to limit this functionality, you can configure an admin admin_key in the plugin settings. When configured, only "create" requests that include the correct admin_key value in an "admin_key" property will succeed, and will be rejected otherwise. Notice that you can optionally extend this functionality to RTP forwarding as well, in order to only allow trusted clients to use that feature.<br><br>
  ///[roomId] : unique numeric ID, optional, chosen by plugin if missing.<br>
  ///[permanent] : true|false, whether the room should be saved in the config file, default=false.<br>
  ///[description] : pretty name of the room, optional.<br>
  ///[secret] : password required to edit/destroy the room, optional.<br>
  ///[pin] : password required to join the room, optional.<br>
  ///[isPrivate] : true|false, whether the room should appear in a list request.<br>
  ///[adminKey] : plugin administrator key; mandatory if configured.<br>
  ///[history] : number of messages to store as a history, and send back to new participants (default=0, no history)<br>
  Future<dynamic> createRoom({String? roomId, String? adminKey, String? description, String? secret, String? pin, bool? isPrivate, int? history, bool? permanent}) async {
    var payload = {
      "textroom": "create",
      "room": roomId,
      "admin_key": adminKey,
      "description": description,
      "secret": secret,
      "pin": pin,
      "is_private": isPrivate,
      "history": history,
      "permanent": permanent,
    };
    _handleRoomIdTypeDifference(payload);
    _context._logger.fine('createRoom invoked with roomId:$roomId');
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response;
  }

  ///
  /// [editRoom]<br>
  /// this can be used to create a new text room .<br>
  /// Notice that, in general, all users can create rooms. If you want to limit this functionality, you can configure an admin admin_key in the plugin settings. When configured, only "create" requests that include the correct admin_key value in an "admin_key" property will succeed, and will be rejected otherwise. Notice that you can optionally extend this functionality to RTP forwarding as well, in order to only allow trusted clients to use that feature.<br><br>
  ///[roomId] : unique numeric ID, optional, chosen by plugin if missing.<br>
  ///[permanent] : true|false, whether the room should be saved in the config file, default=false.<br>
  ///[description] : pretty name of the room, optional.<br>
  ///[secret] : existing password required to edit/destroy the room, optional.<br>
  ///[newSecret] : new password required to edit/destroy the room, optional.<br>
  ///[pin] : password required to join the room, optional.<br>
  ///[isPrivate] : true|false, whether the room should appear in a list request.<br>
  Future<dynamic> editRoom({String? roomId, String? description, String? secret, String? newSecret, String? pin, bool? isPrivate, bool? permanent}) async {
    var payload = {
      "textroom": "create",
      "room": roomId,
      "secret": secret,
      "permanent": permanent,
      "new_description": description,
      "new_secret": newSecret,
      "new_pin": pin,
      "new_is_private": isPrivate,
    };
    _handleRoomIdTypeDifference(payload);
    _context._logger.fine('editRoom invoked with roomId:$roomId');
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response;
  }
}
