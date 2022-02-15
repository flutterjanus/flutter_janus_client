part of janus_client;

class JanusTextRoomPlugin extends JanusPlugin {
  JanusTextRoomPlugin({handleId, context, transport, session})
      : super(
            context: context,
            handleId: handleId,
            plugin: JanusPlugins.TEXT_ROOM,
            session: session,
            transport: transport);

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
        await this.handleRemoteJsep(event.jsep!);
        var body = {"request": "ack"};
        await this.initDataChannel();
        RTCSessionDescription answer = await this.createAnswer(
            audioSend: false,
            videoSend: false,
            videoRecv: false,
            audioRecv: false);
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
  ///[room] : numeric ID of the room to join.<br>
  ///[username] : unique username to have in the room; mandatory. <br>
  ///[pin] : pin to join the room; mandatory if configured.<br>
  ///[display] : display name to have in the room; optional.<br>
  ///[token] : invitation token, in case the room has an ACL; optional.<br>
  ///[history] : true|false, whether to retrieve history messages when available (default=true).<br>
  ///
  Future<void> joinRoom(int room, String username,
      {String? pin, String? display, String? token, bool? history}) async {
    if (setupDone) {
      _context._logger.info('data channel is open, now trying to join');
      var register = {
        'textroom': "join",
        'transaction': randomString(),
        'room': room,
        'username': username,
        'display': display,
        "pin": pin,
        "token": token,
        "history": history
      }..removeWhere((key, value) => value == null);
      await this.sendData(stringify(register));
    } else {
      _context._logger.shout(
          'method was called before calling setup(), hence aborting further operation.');
      throw "method was called before calling setup(), hence aborting further operation.";
    }
  }

  /// [leaveRoom]
  ///
  /// you use a leave request to leave already joined Text Room, make sure to call [setup] before calling [leaveRoom]<br><br>
  ///[room] : numeric ID of the room to join.<br>
  ///
  Future<void> leaveRoom(int room) async {
    if (setupDone) {
      _context._logger.fine('trying to leave room $room');
      var payload = {"textroom": "leave", "room": room};
      await this.sendData(stringify(payload));
    } else {
      _context._logger.shout(
          'method was called before calling setup(), hence aborting further operation.');
      throw "method was called before calling setup(), hence aborting further operation.";
    }
  }

  /// [sendMessage]
  ///[room] : numeric ID of the room to join.<br>
  ///[text] : content of the message to send, as a string.<br>
  ///[ack] : true|false, whether the sender wants an ack for the sent message(s); optional, true by default <br>.
  ///[to] : username to send the message to; optional, only needed in case of private messages. <br>
  ///[tos] : array of usernames to send the message to; optional, only needed in case of private messages. <br>
  Future<void> sendMessage(int room, String text,
      {bool? ack, String? to, List<String>? tos}) async {
    if (setupDone) {
      var message = {
        'transaction': randomString(),
        "textroom": "message",
        "room": room,
        "text": text,
        "to": to,
        "tos": tos,
        "ack": ack
      }..removeWhere((key, value) => value == null);
      _context._logger
          .fine('sending text message to room:$room with payload:$message');
      await this.sendData(stringify(message));
    } else {
      _context._logger.shout(
          'method was called before calling setup(), hence aborting further operation.');
      throw "method was called before calling setup(), hence aborting further operation.";
    }
  }

  Future<dynamic> listRooms() async {
    var payload = {
      "textroom": "list",
    };
  }

  Future<dynamic> listParticipants(int roomId) async {
    var payload = {"request": "listparticipants", "room": roomId};
  }

  Future<dynamic> exists(roomId) async {
    var payload = {"textroom": "exists", "room": roomId};
  }

  /// [kickParticipant]
  ///
  /// If you're the administrator of a room (that is, you created it and have access to the secret) you can kick out individual participant.
  /// [roomId] unique numeric ID of the room to stop the forwarder from.<br>
  /// [username] username of the participant to kick.<br>
  /// [secret] admin secret should be provided if configured.<br>
  Future<dynamic> kickParticipant(int roomId, String username,
      {String? secret}) async {
    var payload = {
      "request": "kick",
      "secret": secret,
      "room": roomId,
      "username": username
    }..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
    return response.plugindata?.data;
  }

  ///
  /// [destroyRoom]<br>
  /// this can be used to destroy a room .<br>
  /// Notice that, in general, all users can create rooms. If you want to limit this functionality, you can configure an admin admin_key in the plugin settings. When configured, only "create" requests that include the correct admin_key value in an "admin_key" property will succeed, and will be rejected otherwise. Notice that you can optionally extend this functionality to RTP forwarding as well, in order to only allow trusted clients to use that feature.<br><br>
  ///[roomId] : unique numeric ID, optional, chosen by plugin if missing.<br>
  ///[permanent] : true|false, whether the room should be also removed from the config file; default=false.<br>
  ///[secret] : password required to edit/destroy the room, optional.<br>
  Future<dynamic> destroyRoom(
      {int? roomId, String? secret, bool? permanent}) async {
    var payload = {
      "textroom": "destroy",
      "room": roomId,
      "secret": secret,
      "permanent": permanent,
    };
  }

  ///
  /// [createRoom]<br>
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
  Future<dynamic> createRoom(
      {int? roomId,
      String? adminKey,
      String? description,
      String? secret,
      String? pin,
      bool? isPrivate,
      int? history,
      bool? permanent}) async {
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
  Future<dynamic> editRoom(
      {int? roomId,
      String? description,
      String? secret,
      String? newSecret,
      String? pin,
      bool? isPrivate,
      bool? permanent}) async {
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
  }
}
