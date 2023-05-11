part of janus_client;

abstract class JanusPlugins {
  static const VIDEO_ROOM = "janus.plugin.videoroom";
  static const AUDIO_BRIDGE = "janus.plugin.audiobridge";
  static const STREAMING = "janus.plugin.streaming";
  static const VIDEO_CALL = "janus.plugin.videocall";
  static const TEXT_ROOM = "janus.plugin.textroom";
  static const ECHO_TEST = "janus.plugin.echotest";
  static const SIP = "janus.plugin.sip";
}

class JanusPlugin {
  void onCreate() {}
  int? handleId;
  late JanusClient _context;
  late JanusTransport? _transport;
  late JanusSession? _session;
  String? plugin;
  bool _initialized = false;

  // internal method which takes care of type of roomId which is normally int but can be string if set in janus config for room
  _handleRoomIdTypeDifference(dynamic payload) {
    if (payload["room"] != null) {
      payload["room"] = _context._stringIds == false ? payload["room"] : payload["room"].toString();
    }
  }

  late Stream<dynamic> _events;
  Stream<EventMessage>? messages;
  Stream<TypedEvent<JanusEvent>>? typedMessages;
  Stream<RTCDataChannelMessage>? data;
  Stream<RTCDataChannelState>? onData;
  Stream<RemoteTrack>? remoteTrack;
  Stream<dynamic>? renegotiationNeeded;
  Stream<MediaStream>? remoteStream;
  Stream<MediaStream?>? localStream;
  StreamController<dynamic>? _renegotiationNeededController;
  StreamController<MediaStream?>? _localStreamController;
  StreamController<RemoteTrack>? _remoteTrackStreamController;
  StreamController<MediaStream>? _remoteStreamController;
  StreamController<dynamic>? _streamController;
  StreamController<EventMessage>? _messagesStreamController;
  StreamController<TypedEvent>? _typedMessagesStreamController;
  StreamController<RTCDataChannelMessage>? _dataStreamController;
  StreamController<RTCDataChannelState>? _onDataStreamController;

  StreamSink? get _typedMessagesSink => _typedMessagesStreamController?.sink;

  int _pollingRetries = 0;
  Timer? _pollingTimer;
  JanusWebRTCHandle? webRTCHandle;
  Map<String, dynamic>? _webRtcConfiguration;

  //temporary variables
  StreamSubscription? _wsStreamSubscription;
  late bool pollingActive;

  JanusPlugin({this.handleId, required JanusClient context, required JanusTransport transport, required JanusSession session, this.plugin}) {
    _context = context;
    _session = session;
    _transport = transport;
  }

  /// used to initialize/reinitialize entire webrtc stack if it is required for your application purpose
  Future<void> initializeWebRTCStack() async {
    if (_webRtcConfiguration == null) {
      _context._logger.shout('initializeWebRTCStack:-configuration is null call init before calling me');
      return;
    }
    _context._logger.finest('webRTC stack intialized');
    RTCPeerConnection peerConnection = await createPeerConnection(_webRtcConfiguration!, {});
    peerConnection.onRenegotiationNeeded = () {
      _renegotiationNeededController?.sink.add(true);
    };
    //unified plan webrtc tracks emitter
    _handleUnifiedWebRTCTracksEmitter(peerConnection);
    //send ice candidates to janus server on this specific handle
    _handleIceCandidatesSending(peerConnection);
    webRTCHandle = JanusWebRTCHandle(peerConnection: peerConnection);
  }

  // used internally for initializing plugin, exposed only to be called via [JanusSession] attach method.
  // `not useful for external operations`
  Future<void> _init() async {
    if (!_initialized) {
      _initialized = true;
      _context._logger.info("Plugin Initialized");
      if (webRTCHandle != null) {
        return;
      }
      // initializing WebRTC Handle
      _webRtcConfiguration = {"iceServers": _context._iceServers != null ? _context._iceServers!.map((e) => e.toMap()).toList() : []};
      if (_context._isUnifiedPlan && !_context._usePlanB) {
        _webRtcConfiguration?.putIfAbsent('sdpSemantics', () => 'unified-plan');
      } else {
        _webRtcConfiguration?.putIfAbsent('sdpSemantics', () => 'plan-b');
      }
      _context._logger.fine('peer connection configuration');
      _context._logger.fine(_webRtcConfiguration);
      await initializeWebRTCStack();
      //initialize stream controllers and streams
      _initStreamControllersAndStreams();
      //add Event emitter logic
      _handleEventMessageEmitter();
      this.pollingActive = true;
      // Warning no code should be placed after code below in init function
      // depending on transport setup events and messages for session and plugin
      _handleTransportInitialization();
    } else {
      _context._logger.info("Plugin already Initialized! skipping");
    }
  }

  void _handleTransportInitialization() {
    if (_transport is RestJanusTransport) {
      _pollingTimer = Timer.periodic(_context._pollingInterval, (timer) async {
        if (!pollingActive) {
          timer.cancel();
        }
        await _handlePolling();
      });
    } else if (_transport is WebSocketJanusTransport) {
      _wsStreamSubscription = (_transport as WebSocketJanusTransport).stream.listen((event) {
        _streamController!.add(parse(event));
      });
    }
  }

  void _initStreamControllersAndStreams() {
    //source and stream for session level events
    _streamController = StreamController<dynamic>();
    _events = _streamController!.stream.asBroadcastStream();
    //source and stream for localStream
    _localStreamController = StreamController<MediaStream?>();
    localStream = _localStreamController!.stream.asBroadcastStream();
    //source and stream for plugin level events
    _messagesStreamController = StreamController<EventMessage>();
    messages = _messagesStreamController!.stream.asBroadcastStream();

    //typed source and stream for plugin level events
    _typedMessagesStreamController = StreamController<TypedEvent<JanusEvent>>();
    typedMessages = _typedMessagesStreamController!.stream.asBroadcastStream() as Stream<TypedEvent<JanusEvent>>?;

    // remote track for unified plan support
    _remoteTrackStreamController = StreamController<RemoteTrack>();
    remoteTrack = _remoteTrackStreamController!.stream.asBroadcastStream();
    // remote MediaStream plan-b
    _remoteStreamController = StreamController<MediaStream>();
    remoteStream = _remoteStreamController!.stream.asBroadcastStream();

    // data channel stream contoller
    _dataStreamController = StreamController<RTCDataChannelMessage>();
    data = _dataStreamController!.stream.asBroadcastStream();

    // data channel state stream contoller
    _onDataStreamController = StreamController<RTCDataChannelState>();
    onData = _onDataStreamController!.stream.asBroadcastStream();
    // data channel state stream contoller
    _renegotiationNeededController = StreamController<void>();
    renegotiationNeeded = _renegotiationNeededController!.stream.asBroadcastStream();
  }

  void _handleUnifiedWebRTCTracksEmitter(RTCPeerConnection peerConnection) {
    if (_context._isUnifiedPlan && !_context._usePlanB) {
      peerConnection.onTrack = (RTCTrackEvent event) async {
        _context._logger.finest('onTrack called with event');
        _context._logger.fine(event.toString());
        if (event.streams.isEmpty) return;
        // Notify about the new track event

        var mid = event.transceiver != null
            ? event.transceiver?.mid
            : event.receiver != null
                ? event.receiver?.track?.id
                : event.track.id;
        _remoteTrackStreamController?.add(RemoteTrack(track: event.track, mid: mid, flowing: true));
        event.track.onEnded = () async {
          // Notify the application
          if (!_remoteTrackStreamController!.isClosed) _remoteTrackStreamController?.add(RemoteTrack(track: event.track, mid: mid, flowing: false));
        };
        event.track.onMute = () async {
          if (!_remoteTrackStreamController!.isClosed) _remoteTrackStreamController?.add(RemoteTrack(track: event.track, mid: mid, flowing: false));
        };
        event.track.onUnMute = () async {
          if (!_remoteTrackStreamController!.isClosed) _remoteTrackStreamController?.add(RemoteTrack(track: event.track, mid: mid, flowing: true));
        };
      };
    }
    // source for onRemoteStream
    peerConnection.onAddStream = (mediaStream) {
      _remoteStreamController!.sink.add(mediaStream);
    };
  }

  void _handleIceCandidatesSending(RTCPeerConnection peerConnection) {
    // get ice candidates and send to janus on this plugin handle
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) async {
      Map<String, dynamic>? response;
      if (!plugin!.contains('textroom')) {
        this._context._logger.finest('sending trickle');
        Map<String, dynamic> request = {"janus": "trickle", "candidate": candidate.toMap(), "transaction": getUuid().v4(), ..._context._apiMap, ..._context._tokenMap};
        request["session_id"] = _session!.sessionId;
        request["handle_id"] = handleId;
        //checking and posting using websocket if in available
        if (_transport is RestJanusTransport) {
          RestJanusTransport rest = (_transport as RestJanusTransport);
          response = (await rest.post(request, handleId: handleId)) as Map<String, dynamic>;
        } else if (_transport is WebSocketJanusTransport) {
          WebSocketJanusTransport ws = (_transport as WebSocketJanusTransport);
          response = (await ws.send(request, handleId: handleId)) as Map<String, dynamic>;
        }
        _streamController!.sink.add(response);
      }
    };
  }

  void _handleEventMessageEmitter() {
    //filter and only send events for current handleId
    _events.where((event) {
      Map<String, dynamic> result = event;
      if (result.containsKey('sender')) {
        if ((result['sender'] as int?) == handleId) return true;
        return false;
      } else {
        return false;
      }
    }).listen((event) {
      var jsep = event['jsep'];
      if (jsep != null) {
        _messagesStreamController!.sink.add(EventMessage(event: event, jsep: RTCSessionDescription(jsep['sdp'], jsep['type'])));
      } else {
        _addTrickleCandidate(event);
        _messagesStreamController!.sink.add(EventMessage(event: event, jsep: null));
      }
    });
  }

  void _addTrickleCandidate(event) {
    final isTrickleEvent = event['janus'] == 'trickle';
    if (isTrickleEvent) {
      final candidateMap = event['candidate'];
      RTCIceCandidate candidate = RTCIceCandidate(candidateMap['candidate'], candidateMap['sdpMid'], candidateMap['sdpMLineIndex']);
      webRTCHandle!.peerConnection!.addCandidate(candidate);
    }
  }

  _handlePolling() async {
    if (!pollingActive) return;
    if (_session!.sessionId == null) {
      pollingActive = false;
      return;
    }
    try {
      var longpoll = _transport!.url! + "/" + _session!.sessionId.toString() + "?rid=" + new DateTime.now().millisecondsSinceEpoch.toString();
      if (_context._maxEvent != null) longpoll = longpoll + "&maxev=" + _context._maxEvent.toString();
      if (_context._token != null) longpoll = longpoll + "&token=" + _context._token!;
      if (_context._apiSecret != null) longpoll = longpoll + "&apisecret=" + _context._apiSecret!;
      List<dynamic> json = parse((await http.get(Uri.parse(longpoll))).body);
      json.forEach((element) {
        if (!_streamController!.isClosed) {
          _streamController!.add(element);
        } else {
          pollingActive = false;
          return;
        }
      });
      _pollingRetries = 0;
      return;
    } on HttpException catch (_) {
      _pollingRetries++;
      pollingActive = false;
      if (_pollingRetries > 2) {
        // Did we just lose the server? :-(
        _context._logger.severe("Lost connection to the server (is it down?)");
        return;
      }
    } catch (e) {
      this._context._logger.fine(e);
      pollingActive = false;
      _context._logger.severe("fatal Exception");
      return;
    }
    return;
  }

  /// You can check whether a room exists using the exists
  Future<dynamic> exists(int roomId) async {
    var payload = {"request": "exists", "room": roomId};
    return (await this.send(data: payload));
  }

  void _cancelPollingTimer() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
    }
  }

  Future<void> hangup() async {
    _cancelPollingTimer();
    await _disposeMediaStreams();
  }

  Future<void> _disposeMediaStreams({ignoreRemote = false, video = true, audio = true}) async {
    _context._logger.finest('disposing localStream and remoteStream if it already exists');
    if (webRTCHandle!.localStream != null) {
      if (audio) {
        webRTCHandle?.localStream?.getAudioTracks().forEach((element) async {
          await element.stop();
        });
      }
      if (video) {
        webRTCHandle?.localStream?.getVideoTracks().forEach((element) async {
          await element.stop();
        });
      }
      if (audio && video) {
        webRTCHandle?.localStream?.dispose();
      }
    }
    if (webRTCHandle!.remoteStream != null && !ignoreRemote) {
      webRTCHandle?.remoteStream?.getTracks().forEach((element) async {
        await element.stop();
      });
      webRTCHandle?.remoteStream?.dispose();
    }
  }

  /// This function takes care of cleaning up all the internal stream controller and timers used to make janus_client compatible with streams and polling support
  ///
  Future<void> dispose() async {
    this.pollingActive = false;
    _pollingTimer?.cancel();
    _streamController?.close();
    _remoteStreamController?.close();
    _messagesStreamController?.close();
    _typedMessagesStreamController?.close();
    _localStreamController?.close();
    _remoteTrackStreamController?.close();
    _dataStreamController?.close();
    _onDataStreamController?.close();
    _renegotiationNeededController?.close();
    _wsStreamSubscription?.cancel();

    await stopAllTracksAndDispose(webRTCHandle?.localStream);
    await webRTCHandle?.peerConnection?.close();
    await webRTCHandle?.remoteStream?.dispose();
    await webRTCHandle?.localStream?.dispose();
    await webRTCHandle?.peerConnection?.dispose();
  }

  /// this method Initialize data channel on handle's internal peer connection object.
  /// It is mainly used for Janus TextRoom and can be used for other plugins with data channel support
  Future<void> initDataChannel({RTCDataChannelInit? rtcDataChannelInit}) async {
    if (webRTCHandle!.peerConnection != null) {
      if (webRTCHandle!.dataChannel[_context._dataChannelDefaultLabel] != null) return;
      if (rtcDataChannelInit == null) {
        rtcDataChannelInit = RTCDataChannelInit();
        rtcDataChannelInit.ordered = true;
        rtcDataChannelInit.protocol = 'janus-protocol';
      }
      webRTCHandle!.dataChannel[_context._dataChannelDefaultLabel] = await webRTCHandle!.peerConnection!.createDataChannel(_context._dataChannelDefaultLabel, rtcDataChannelInit);
      if (webRTCHandle!.dataChannel[_context._dataChannelDefaultLabel] != null) {
        webRTCHandle!.dataChannel[_context._dataChannelDefaultLabel]!.onDataChannelState = (state) {
          if (!_onDataStreamController!.isClosed) {
            _onDataStreamController!.sink.add(state);
          }
        };
        webRTCHandle!.dataChannel[_context._dataChannelDefaultLabel]!.onMessage = (RTCDataChannelMessage message) {
          if (!_dataStreamController!.isClosed) {
            _dataStreamController!.sink.add(message);
          }
        };
      }
    } else {
      throw Exception("You Must Initialize Peer Connection before even attempting data channel creation!");
    }
  }

  /// This method is crucial for communicating with Janus Server's APIs it takes in data and optionally jsep for negotiating with webrtc peers
  Future<dynamic> send({dynamic data, RTCSessionDescription? jsep}) async {
    try {
      String transaction = getUuid().v4();
      Map<String, dynamic>? response;
      Map<String, dynamic> request = {"janus": "message", "body": data, "transaction": transaction, ..._context._apiMap, ..._context._tokenMap};
      if (jsep != null) {
        _context._logger.finest("sending jsep");
        _context._logger.finest(jsep.toMap());
        request["jsep"] = jsep.toMap();
      }
      if (_transport is RestJanusTransport) {
        RestJanusTransport rest = (_transport as RestJanusTransport);
        response = (await rest.post(request, handleId: handleId)) as Map<String, dynamic>;
      } else if (_transport is WebSocketJanusTransport) {
        WebSocketJanusTransport ws = (_transport as WebSocketJanusTransport);
        if (!ws.isConnected) {
          return;
        }
        response = await ws.send(request, handleId: handleId);
      }
      return response;
    } catch (e) {
      this._context._logger.fine(e);
    }
  }

  /// It allows you to set Remote Description on internal peer connection, Received from janus server
  Future<void> handleRemoteJsep(RTCSessionDescription? data) async {
    // var state = webRTCHandle?.peerConnection?.signalingState;
    if (data != null) {
      await webRTCHandle?.peerConnection?.setRemoteDescription(data);
    }
  }

  /// method that generates MediaStream from your device camera that will be automatically added to peer connection instance internally used by janus client
  ///
  /// [useDisplayMediaDevices] : setting this true will give you capabilities to stream your device screen over PeerConnection.<br>
  /// [mediaConstraints] : using this map you can specify media contraits such as resolution and fps etc.
  /// you can use this method to get the stream and show live preview of your camera to RTCVideoRendererView
  Future<MediaStream?> initializeMediaDevices({bool? useDisplayMediaDevices = false, Map<String, dynamic>? mediaConstraints}) async {
    await _disposeMediaStreams(ignoreRemote: true);
    List<MediaDeviceInfo> videoDevices = await getVideoInputDevices();
    List<MediaDeviceInfo> audioDevices = await getAudioInputDevices();
    if (videoDevices.isEmpty && audioDevices.isEmpty) {
      throw Exception("No device found for media generation");
    }
    if (mediaConstraints == null) {
      if (videoDevices.isEmpty && audioDevices.isNotEmpty) {
        mediaConstraints = {"audio": true, "video": false};
      } else if (videoDevices.length == 1 && audioDevices.isNotEmpty) {
        mediaConstraints = {"audio": true, 'video': true};
      } else {
        mediaConstraints = {
          "audio": audioDevices.length > 0,
          'video': {
            'deviceId': {'exact': videoDevices.first.deviceId},
          },
        };
      }
    }
    _context._logger.fine(mediaConstraints);
    if (webRTCHandle != null) {
      if (useDisplayMediaDevices == true) {
        webRTCHandle!.localStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      } else {
        webRTCHandle!.localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      }
      if (_context._isUnifiedPlan && !_context._usePlanB) {
        _context._logger.finest('using unified plan');
        webRTCHandle!.localStream!.getTracks().forEach((element) async {
          _context._logger.finest('adding track in peerconnection');
          _context._logger.finest(element.toString());
          await webRTCHandle!.peerConnection!.addTrack(element, webRTCHandle!.localStream!);
        });
      } else {
        _localStreamController!.sink.add(webRTCHandle!.localStream);
        await webRTCHandle!.peerConnection!.addStream(webRTCHandle!.localStream!);
      }
      return webRTCHandle!.localStream;
    } else {
      _context._logger.severe("error webrtchandle cant be null");
      return null;
    }
  }

  Future<List<MediaDeviceInfo>> getVideoInputDevices() async {
    return (await navigator.mediaDevices.enumerateDevices()).where((element) => element.kind == 'videoinput').toList();
  }

  Future<List<MediaDeviceInfo>> getAudioInputDevices() async {
    return (await navigator.mediaDevices.enumerateDevices()).where((element) => element.kind == 'audioinput').toList();
  }

  /// a utility method which can be used to switch camera of user device if it has more than one camera
  /// [deviceId] : device id of the camera you want to switch to
  /// [deviceId] is important for switchCamera to work in browsers.
  Future<bool> switchCamera({String? deviceId}) async {
    List<MediaDeviceInfo> videoDevices = await getVideoInputDevices();
    if (videoDevices.isEmpty) {
      throw Exception("No Camera Found");
    }
    if (kIsWeb) {
      if (deviceId == null) {
        _context._logger.finest('deviceId not provided,hence switching to default last deviceId should be of back camera ideally');
        deviceId = videoDevices.last.deviceId;
      }
      await _disposeMediaStreams(ignoreRemote: true);
      webRTCHandle!.localStream = await navigator.mediaDevices.getUserMedia({
        'video': {
          'deviceId': {'exact': deviceId}
        },
        'audio': true
      });
      List<RTCRtpSender> senders = (await webRTCHandle!.peerConnection!.getSenders());
      webRTCHandle!.localStream?.getTracks().forEach((element) async {
        senders.forEach((sender) async {
          if (sender.track?.kind == element.kind) {
            await sender.replaceTrack(element);
          }
        });
      });
      return true;
    } else {
      if (webRTCHandle?.localStream != null) {
        _context._logger.finest('using helper to switch camera, only works in android and ios');
        return Helper.switchCamera(webRTCHandle!.localStream!.getVideoTracks().first);
      }
      return false;
    }
  }

  /// This method is used to create webrtc offer, sets local description on internal PeerConnection object
  /// It supports both style of offer creation that is plan-b and unified.
  Future<RTCSessionDescription> createOffer({bool audioRecv: true, bool videoRecv: true, bool audioSend: true, bool videoSend: true}) async {
    dynamic offerOptions;
    if (_context._isUnifiedPlan && !_context._usePlanB) {
      await _prepareTranscievers(audioRecv: audioRecv, audioSend: audioSend, videoRecv: videoRecv, videoSend: videoSend);
      offerOptions = {"offerToReceiveAudio": audioRecv, "offerToReceiveVideo": videoRecv};
    }
    RTCSessionDescription offer = await webRTCHandle!.peerConnection!.createOffer(offerOptions ?? {});
    await webRTCHandle!.peerConnection!.setLocalDescription(offer);
    return offer;
  }

  /// This method is used to create webrtc answer, sets local description on internal PeerConnection object
  /// It supports both style of answer creation that is plan-b and unified.
  Future<RTCSessionDescription> createAnswer({bool audioRecv: true, bool videoRecv: true, bool audioSend: true, bool videoSend: true}) async {
    dynamic offerOptions;
    if (_context._isUnifiedPlan && !_context._usePlanB) {
      await _prepareTranscievers(audioRecv: audioRecv, audioSend: audioSend, videoRecv: videoRecv, videoSend: videoSend);
    } else {
      offerOptions = {"offerToReceiveAudio": audioRecv, "offerToReceiveVideo": videoRecv};
    }
    try {
      RTCSessionDescription offer = await webRTCHandle!.peerConnection!.createAnswer(offerOptions ?? {});
      await webRTCHandle!.peerConnection!.setLocalDescription(offer);
      return offer;
    } catch (e) {
      //    handling kstable exception most ugly way but currently there's no other workaround, it just works
      RTCSessionDescription offer = await webRTCHandle!.peerConnection!.createAnswer(offerOptions ?? {});
      await webRTCHandle!.peerConnection!.setLocalDescription(offer);
      return offer;
    }
  }

  Future<RTCSessionDescription?> createNullableAnswer({bool audioRecv: true, bool videoRecv: true, bool audioSend: true, bool videoSend: true}) async {
    dynamic offerOptions;
    if (_context._isUnifiedPlan && !_context._usePlanB) {
      await _prepareTranscievers(audioRecv: audioRecv, audioSend: audioSend, videoRecv: videoRecv, videoSend: videoSend);
    } else {
      offerOptions = {"offerToReceiveAudio": audioRecv, "offerToReceiveVideo": videoRecv};
    }
    try {
      RTCSessionDescription offer = await webRTCHandle!.peerConnection!.createAnswer(offerOptions ?? {});
      await webRTCHandle!.peerConnection!.setLocalDescription(offer);
      return offer;
    } catch (e) {
      return null;
    }
  }

  /// Send text message on existing text room using data channel with same label as specified during initDataChannel() method call.
  ///
  /// for now janus text room only supports text as string although with normal data channel api we can send blob or Uint8List if we want.
  Future<void> sendData(String message) async {
    // if (message != null) {
    if (webRTCHandle!.peerConnection != null) {
      this._context._logger.finest('before send RTCDataChannelMessage');
      if (webRTCHandle!.dataChannel[_context._dataChannelDefaultLabel] == null) {
        throw Exception("You Must  call initDataChannel method! before you can send any data channel message");
      }
      RTCDataChannel dataChannel = webRTCHandle!.dataChannel[_context._dataChannelDefaultLabel]!;
      if (dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
        return await dataChannel.send(RTCDataChannelMessage(message));
      }
    } else {
      throw Exception("You Must Initialize Peer Connection followed by initDataChannel()");
    }
    // } else {
    //   throw Exception("message must be provided!");
    // }
  }

  Future _prepareTranscievers({bool audioRecv: false, bool videoRecv: false, bool audioSend: true, bool videoSend: true}) async {
    this._context._logger.finest('using transrecievers in prepare transrecievers');
    RTCRtpTransceiver? audioTransceiver;
    RTCRtpTransceiver? videoTransceiver;
    List<RTCRtpTransceiver> transceivers = await webRTCHandle!.peerConnection!.transceivers;
    if (transceivers.length > 0) {
      transceivers.forEach((t) {
        if ((t.sender.track != null && t.sender.track!.kind == "audio") || (t.receiver.track != null && t.receiver.track!.kind == "audio")) {
          if (audioTransceiver == null) {
            audioTransceiver = t;
          }
        }
        if ((t.sender.track != null && t.sender.track!.kind == "video") || (t.receiver.track != null && t.receiver.track!.kind == "video")) {
          if (videoTransceiver == null) {
            videoTransceiver = t;
          }
        }
      });
    }

    if (!audioSend && !audioRecv) {
      // Audio disabled: have we removed it?
      if (audioTransceiver != null) {
        audioTransceiver!.setDirection(TransceiverDirection.Inactive);
        this._context._logger.finest("Setting audio transceiver to inactive:" + audioTransceiver.toString());
      }
    } else {
      // Take care of audio m-line
      if (audioSend && audioRecv) {
        if (audioTransceiver != null) {
          audioTransceiver!.setDirection(TransceiverDirection.SendRecv);
          this._context._logger.finest("Setting audio transceiver to sendrecv:" + audioTransceiver.toString());
        }
      } else if (audioSend && !audioRecv) {
        if (audioTransceiver != null) {
          audioTransceiver!.setDirection(TransceiverDirection.SendOnly);
          this._context._logger.finest("Setting audio transceiver to sendonly:" + audioTransceiver.toString());
        }
      } else if (!audioSend && audioRecv) {
        if (audioTransceiver != null) {
          audioTransceiver!.setDirection(TransceiverDirection.RecvOnly);
          this._context._logger.finest("Setting audio transceiver to recvonly:" + audioTransceiver.toString());
        } else {
          // In theory, this is the only case where we might not have a transceiver yet
          audioTransceiver =
              await webRTCHandle!.peerConnection!.addTransceiver(kind: RTCRtpMediaType.RTCRtpMediaTypeAudio, init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
          this._context._logger.finest("Adding recvonly audio transceiver:" + audioTransceiver.toString());
        }
      }
    }
    if (!videoSend && !videoRecv) {
      // Video disabled: have we removed it?
      if (videoTransceiver != null) {
        videoTransceiver!.setDirection(TransceiverDirection.Inactive);
        // Janus.log("Setting video transceiver to inactive:", videoTransceiver);
      }
    } else {
      // Take care of video m-line
      if (videoSend && videoRecv) {
        if (videoTransceiver != null) {
          videoTransceiver!.setDirection(TransceiverDirection.SendRecv);
          // Janus.log("Setting video transceiver to sendrecv:", videoTransceiver);
        }
      } else if (videoSend && !videoRecv) {
        if (videoTransceiver != null) {
          videoTransceiver!.setDirection(TransceiverDirection.SendOnly);
          // Janus.log("Setting video transceiver to sendonly:", videoTransceiver);
        }
      } else if (!videoSend && videoRecv) {
        if (videoTransceiver != null) {
          videoTransceiver!.setDirection(TransceiverDirection.RecvOnly);
          // Janus.log("Setting video transceiver to recvonly:", videoTransceiver);
        } else {
          // In theory, this is the only case where we might not have a transceiver yet
          videoTransceiver =
              await webRTCHandle!.peerConnection!.addTransceiver(kind: RTCRtpMediaType.RTCRtpMediaTypeAudio, init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
        }
      }
    }
  }
}
