part of janus_client;

class JanusVideoCallPlugin extends JanusPlugin {
  JanusVideoCallPlugin({handleId, context, transport, session})
      : super(context: context, handleId: handleId, plugin: JanusPlugins.VIDEO_CALL, session: session, transport: transport);

  /// Get List of peers
  ///
  ///    `sends request with payload as:  `
  ///    `{"request": "list"}`
  ///
  /// since it is asynchronous request result can only be extracted from event messages
  ///
  Future<void> getList() async {
    const payload = {"request": "list"};
    await this.send(data: payload);
  }

  /// Register User / Call Participant
  ///
  ///    `sends request with payload as:  `
  ///    `{"request": "register", "username": userName}`
  ///
  /// since it is asynchronous request result can only be extracted from event messages
  ///
  Future<void> register(String userName) async {
    var payload = {"request": "register", "username": userName};
    await this.send(data: payload);
  }

  /// Call other participant
  ///
  ///    `sends request with payload as:  `
  ///    `{
  ///       "request" : "call",
  ///       "username" : userName
  ///     }`
  ///  along with the payload it internally creates the offer with `sendRecv` true and sends it.
  ///
  ///  Optionally you can provide your own offer if you want, in offer property.
  ///
  /// Since it is asynchronous request result can only be extracted from event messages
  ///
  ///
  Future<void> call(String userName, {RTCSessionDescription? offer}) async {
    var payload = {"request": "call", "username": userName};
    if (offer == null) {
      offer = await createOffer(audioRecv: true, videoRecv: true);
    }
    await this.send(data: payload, jsep: offer);
  }

  /// Accept the incoming call
  ///
  ///    `sends request with payload as:  `
  ///    `{
  ///       "request" : "accept",
  ///
  ///     }`
  ///  along with the payload it internally creates the answer with `sendRecv` true and sends it.
  ///
  ///  Optionally you can provide your own answer if you want, in answer property.
  ///
  /// Since it is asynchronous request result can only be extracted from event messages
  ///
  ///
  Future<void> acceptCall({RTCSessionDescription? answer}) async {
    var payload = {"request": "accept"};
    if (answer == null) {
      answer = await createAnswer();
    }
    await this.send(data: payload, jsep: answer);
  }

  /// Hangup the  call
  ///
  ///    `sends request with payload as:  `
  ///    `{
  ///       "request" : "hangup"
  ///     }`
  /// Since it is asynchronous request result can only be extracted from event messages
  ///
  ///
  Future<void> hangup() async {
    await super.hangup();
    await this.send(data: {"request": "hangup"});
    dispose();
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
      if (data['videocall'] == 'event' && data['result'] != null && data['result']['event'] == 'registered') {
        typedEvent.event.plugindata?.data = VideoCallRegisteredEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videocall'] == 'event' && data['result'] != null && data['result']['event'] == 'calling') {
        typedEvent.event.plugindata?.data = VideoCallCallingEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videocall'] == 'event' && data['result'] != null && data['result']['event'] == 'incomingcall') {
        typedEvent.event.plugindata?.data = VideoCallIncomingCallEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videocall'] == 'event' && data['result'] != null && data['result']['event'] == 'accepted') {
        typedEvent.event.plugindata?.data = VideoCallAcceptedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videocall'] == 'event' && data['result'] != null && data['result']['event'] == 'hangup') {
        typedEvent.event.plugindata?.data = VideoCallHangupEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['videocall'] == 'event' && (data['error_code'] != null || data['result']?['code'] != null)) {
        _typedMessagesSink?.addError(JanusError.fromMap(data));
      }
    });
  }
}
