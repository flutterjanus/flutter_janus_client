part of janus_client;

enum SipHoldState { SENDONLY, RECVONLY, INACTIVE }

class JanusSipPlugin extends JanusPlugin {
  bool _onCreated = false;
  JanusSipPlugin({handleId, context, transport, session}) : super(context: context, handleId: handleId, plugin: JanusPlugins.SIP, session: session, transport: transport);

  /// Register client to sip server
  /// [username] : SIP URI to register
  /// [type] : if guest or helper, no SIP REGISTER is actually sent; optional
  /// [sendRegister] : true|false; if false, no SIP REGISTER is actually sent; optional
  Future<void> register(
    String username, {
    String? type,
    bool? sendRegister,
    bool? forceUdp,
    bool? forceTcp,
    bool? sips,
    bool? rfc2543Cancel,
    bool? refresh,
    String? secret,
    String? ha1Secret,
    String? authuser,
    String? displayName,
    String? userAgent,
    String? proxy,
    String? outboundProxy,
    Map<String, dynamic>? headers,
    List<Map<String, dynamic>>? contactParams,
    List<String>? incomingHeaderPrefixes,
    String? masterId,
    int? registerTtl,
  }) async {
    var payload = {
      "request": "register",
      "type": type,
      "send_register": sendRegister,
      "force_udp": forceUdp, //<true|false; if true, forces UDP for the SIP messaging; optional>,
      "force_tcp": forceTcp, //<true|false; if true, forces TCP for the SIP messaging; optional>,
      "sips": sips, //<true|false; if true, configures a SIPS URI too when registering; optional>,
      "rfc2543_cancel": rfc2543Cancel, //<true|false; if true, configures sip client to CANCEL pending INVITEs without having received a provisional response first; optional>,
      "username": username,
      "secret": secret, //"<password to use to register; optional>",
      "ha1_secret": ha1Secret, //"<prehashed password to use to register; optional>",
      "authuser": authuser, //"<username to use to authenticate (overrides the one in the SIP URI); optional>",
      "display_name": displayName, //"<display name to use when sending SIP REGISTER; optional>",
      "user_agent": userAgent, //"<user agent to use when sending SIP REGISTER; optional>",
      "proxy": proxy, //"<server to register at; optional, as won't be needed in case the REGISTER is not goint to be sent (e.g., guests)>",
      "outbound_proxy": outboundProxy, //"<outbound proxy to use, if any; optional>",
      "headers": headers, //"<object with key/value mappings (header name/value), to specify custom headers to add to the SIP REGISTER; optional>",
      "contact_params": contactParams, //"<array of key/value objects, to specify custom Contact URI params to add to the SIP REGISTER; optional>",
      "incoming_header_prefixes": incomingHeaderPrefixes, //"<array of strings, to specify custom (non-standard) headers to read on incoming SIP events; optional>",
      "refresh": refresh, //"<true|false; if true, only uses the SIP REGISTER as an update and not a new registration; optional>",
      "master_id": masterId, //"<ID of an already registered account, if this is an helper for multiple calls (more on that later); optional>",
      "register_ttl": registerTtl, //"<integer; number of seconds after which the registration should expire; optional>"
    }..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// Accept Incoming Call
  ///
  /// [sessionDescription] : For accepting the call we can have offerless sip invite too, so here we have intententionaly given flexibility of having either offer or answer depending on what peer is providing  if it is not provided, default offer or answer is created and used with audio as sendrecv depending on the signaling state
  ///
  /// [headers] : object with key/value mappings (header name/value), to specify custom headers to add to the SIP INVITE; optional
  ///
  /// [srtp] : whether to mandate (sdes_mandatory) or offer (sdes_optional) SRTP support; optional
  ///
  /// [autoAcceptReInvites] : whether we should blindly accept re-INVITEs with a 200 OK instead of relaying the SDP to the application; optional, TRUE by default
  Future<void> accept({String? srtp, Map<String, dynamic>? headers, bool? autoAcceptReInvites, RTCSessionDescription? sessionDescription}) async {
    var payload = {"request": "accept", "headers": headers, "srtp": srtp, "autoaccept_reinvites": autoAcceptReInvites}..removeWhere((key, value) => value == null);
    RTCSignalingState? signalingState = this.webRTCHandle?.peerConnection?.signalingState;
    if (sessionDescription == null && signalingState == RTCSignalingState.RTCSignalingStateHaveRemoteOffer) {
      sessionDescription = await this.createAnswer();
    } else if (sessionDescription == null) {
      sessionDescription = await this.createOffer(videoRecv: false, audioRecv: true);
    }
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload, jsep: sessionDescription));
    JanusError.throwErrorFromEvent(response);
  }

  /// unregister from the SIP server.
  Future<void> unregister() async {
    const payload = {"request": "unregister"};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// hangup the call
  /// [headers]: object with key/value mappings (header name/value), to specify custom headers to add to the SIP BYE; optional
  Future<void> hangup({
    Map<String, dynamic>? headers,
  }) async {
    var payload = {"request": "hangup", "headers": headers}..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// decline sip call
  /// [code] : SIP code to be sent, if not set, 486 is used; optional
  /// [headers] : object with key/value mappings (header name/value), to specify custom headers to add to the SIP request; optional
  Future<void> decline({
    int? code,
    Map<String, dynamic>? headers,
  }) async {
    var payload = {"request": "decline", "code": code, "headers": headers}..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// hold sip call
  /// [direction] : specify [SipHoldState] for direction of call flow
  Future<void> hold(
    SipHoldState direction,
  ) async {
    var payload = {"request": "hold", "direction": direction.name};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// unhold sip call
  Future<void> unhold() async {
    var payload = {"request": "unhold"};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// update sip session
  Future<void> update() async {
    const payload = {"request": "update"};
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// initiate sip call invite to provided sip uri.
  /// [uri] : SIP URI to call; mandatory
  /// [callId] : user-defined value of Call-ID SIP header used in all SIP requests throughout the call; optional
  /// [referId] : in case this is the result of a REFER, the unique identifier that addresses it; optional
  /// [headers] : object with key/value mappings (header name/value), to specify custom headers to add to the SIP INVITE; optional
  /// [srtp] : whether to mandate (sdes_mandatory) or offer (sdes_optional) SRTP support; optional
  /// [srtpProfile] : SRTP profile to negotiate, in case SRTP is offered; optional
  /// [autoAcceptReInvites] : whether we should blindly accept re-INVITEs with a 200 OK instead of relaying the SDP to the application; optional, TRUE by default
  /// [offer] : note it by default sends only audio sendrecv offer
  Future<void> call(String uri,
      {String? callId,
      String? referId,
      String? srtp,
      String? secret,
      String? ha1Secret,
      String? authuser,
      Map<String, dynamic>? headers,
      String? srtpProfile,
      bool? autoAcceptReInvites,
      RTCSessionDescription? offer}) async {
    var payload = {
      "request": "call",
      "call_id": callId,
      "uri": uri,
      "refer_id": referId,
      "headers": headers,
      "autoaccept_reinvites": autoAcceptReInvites,
      "srtp": srtp,
      "srtp_profile": srtpProfile,
      "secret": secret, //"<password to use to register; optional>",
      "ha1_secret": ha1Secret, //"<prehashed password to use to register; optional>",
      "authuser": authuser, //"<username to use to authenticate (overrides the one in the SIP URI); optional>",
    }..removeWhere((key, value) => value == null);
    if (offer == null) {
      offer = await this.createOffer(videoRecv: false, audioRecv: true);
    }
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload, jsep: offer));
    JanusError.throwErrorFromEvent(response);
  }

  /// transfer on-going call to another sip uri
  /// [uri] : SIP URI to send the transferee too
  /// [replace]: call-ID of the call this attended transfer is supposed to replace; default is none, which means blind/unattended transfer
  Future<void> transfer(
    String uri, {
    String? replace,
  }) async {
    var payload = {"request": "transfer", "uri": uri, "replace": replace}..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
  }

  /// record on-going call
  /// [state] : true|false, depending on whether you want to start or stop recording something
  /// [audio]: true|false; whether or not our audio should be recorded
  /// [video]: true|false; whether or not our video should be recorded
  /// [peerAudio]: true|false; whether or not our peer's audio should be recorded
  /// [peerVideo]: true|false; whether or not our peer's video should be recorded
  /// [filename]: base path/filename to use for all the recordings
  Future<void> recording(
    bool state, {
    bool? audio,
    bool? video,
    bool? peerAudio,
    bool? peerVideo,
    String? filename,
  }) async {
    var payload = {
      "request": "recording",
      "action": state ? "start" : 'stop',
      "audio": audio,
      "video": video,
      "peer_audio": peerAudio,
      "peer_video": peerVideo,
      "filename": filename
    }..removeWhere((key, value) => value == null);
    JanusEvent response = JanusEvent.fromJson(await this.send(data: payload));
    JanusError.throwErrorFromEvent(response);
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
      if (data["sip"] == "event" && data["result"]?['event'] == "registered") {
        typedEvent.event.plugindata?.data = SipRegisteredEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "unregistered") {
        typedEvent.event.plugindata?.data = SipUnRegisteredEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "ringing") {
        typedEvent.event.plugindata?.data = SipRingingEvent.fromJson(typedEvent.event.plugindata?.data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "calling") {
        typedEvent.event.plugindata?.data = SipCallingEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "proceeding") {
        typedEvent.event.plugindata?.data = SipProceedingEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "accepted") {
        typedEvent.event.plugindata?.data = SipAcceptedEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "progress") {
        typedEvent.event.plugindata?.data = SipProgressEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "incomingcall") {
        typedEvent.event.plugindata?.data = SipIncomingCallEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "missed_call") {
        typedEvent.event.plugindata?.data = SipMissedCallEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data["sip"] == "event" && data["result"]?['event'] == "transfer") {
        typedEvent.event.plugindata?.data = SipTransferCallEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['result']?['code'] != null && data["result"]?['event'] == "hangup" && data['result']?['reason'] != null) {
        typedEvent.event.plugindata?.data = SipHangupEvent.fromJson(data);
        _typedMessagesSink?.add(typedEvent);
      } else if (data['sip'] == 'event' && data['error_code'] != null) {
        _typedMessagesSink?.addError(JanusError.fromMap(data));
      }
    });
  }
}
