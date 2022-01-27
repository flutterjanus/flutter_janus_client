library janus_client;

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as Math;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

part './JanusSession.dart';

part './JanusTransport.dart';

part './JanusPlugin.dart';

part './utils.dart';

part './WrapperPlugins/JanusVideoCallPlugin.dart';

part './WrapperPlugins/JanusSipPlugin.dart';

part './WrapperPlugins/JanusVideoRoomPlugin.dart';

part 'interfaces/TypedEvent.dart';

part './WrapperPlugins/JanusAudioBridgePlugin.dart';

part './WrapperPlugins/JanusStreamingPlugin.dart';

part './WrapperPlugins/JanusTextRoomPlugin.dart';

part './WrapperPlugins/JanusEchoTestPlugin.dart';

part './interfaces/VideoRoom/video_room_list_response.dart';

part './interfaces/VideoRoom/video_room_list_participants_response.dart';

part './interfaces/VideoRoom/Events/video_room_atached_event.dart';

part './interfaces/VideoRoom/Events/video_room_configured.dart';

part './interfaces/VideoRoom/Events/video_room_joined_event.dart';

part './interfaces/VideoRoom/Events/video_room_leaving_event.dart';

part './interfaces/VideoRoom/Events/video_room_new_publisher_event.dart';

part './interfaces/VideoRoom/Events/video_room_event.dart';

part './interfaces/VideoCall/Events/video_call_accepted_event.dart';

part './interfaces/VideoCall/Events/video_call_calling_event.dart';

part './interfaces/VideoCall/Events/video_call_event.dart';

part './interfaces/VideoCall/Events/video_call_hangup_event.dart';

part './interfaces/VideoCall/Events/video_call_incoming_call_event.dart';

part './interfaces/VideoCall/Events/video_call_registered_event.dart';

part './interfaces/Streaming/create_media_item.dart';

part './interfaces/Streaming/streaming_mount.dart';

part './interfaces/Streaming/streaming_mount_edited.dart';

part './interfaces/Streaming/streaming_mount_point.dart';

part './interfaces/Streaming/streaming_mount_point_info.dart';

part './interfaces/Streaming/Events/StreamingPluginPreparingEvent.dart';

part './interfaces/Streaming/Events/StreamingPluginStoppingEvent.dart';

part './interfaces/AudioBridge/audio_room_created_response.dart';

part './interfaces/AudioBridge/rtp_forward_stopped.dart';

part './interfaces/AudioBridge/rtp_forwarder_created.dart';

part './interfaces/AudioBridge/Events/audio_bridge_configured_event.dart';

part './interfaces/AudioBridge/Events/audio_bridge_event.dart';

part './interfaces/AudioBridge/Events/audio_bridge_joined_event.dart';

part './interfaces/AudioBridge/Events/audio_bridge_leaving_event.dart';

class JanusClient {
  late JanusTransport _transport;
  String? _apiSecret;
  String? _token;
  late Duration _pollingInterval;
  late bool _withCredentials;
  late int _maxEvent;
  late List<RTCIceServer>? _iceServers = [];
  late int _refreshInterval;
  late bool _isUnifiedPlan;
  late String _loggerName;
  late bool _usePlanB;
  late Logger _logger;
  late Level _loggerLevel;

  /*
  * // According to this [Issue](https://github.com/meetecho/janus-gateway/issues/124) we cannot change Data channel Label
  * */
  String get _dataChannelDefaultLabel => "JanusDataChannel";

  Map get _apiMap => _withCredentials
      ? _apiSecret != null
          ? {"apisecret": _apiSecret}
          : {}
      : {};

  Map get _tokenMap => _withCredentials
      ? _token != null
          ? {"token": _token}
          : {}
      : {};

  /// JanusClient
  ///
  /// setting usePlanB forces creation of peer connection with plan-b sdb semantics,
  /// and would cause isUnifiedPlan to have no effect on sdpSemantics config
  JanusClient(
      {required JanusTransport transport,
      List<RTCIceServer>? iceServers,
      int refreshInterval = 50,
      String? apiSecret,
      bool isUnifiedPlan = true,
      String? token,

      /// forces creation of peer connection with plan-b sdb semantics
      @Deprecated('set this option to true if you using legacy janus plugins with no unified-plan support only.') bool usePlanB = false,
      Duration? pollingInterval,
      loggerName = "JanusClient",
      maxEvent = 10,
      loggerLevel = Level.ALL,
      bool withCredentials = false}) {
    _transport = transport;
    _isUnifiedPlan = isUnifiedPlan;
    _iceServers = iceServers;
    _refreshInterval = refreshInterval;
    _apiSecret = _apiSecret;
    _loggerName = loggerName;
    _maxEvent = maxEvent;
    _loggerLevel = loggerLevel;
    _withCredentials = withCredentials;
    _isUnifiedPlan = isUnifiedPlan;
    _token = token;
    _pollingInterval = pollingInterval ?? Duration(seconds: 1);
    _usePlanB = usePlanB;
    _logger = Logger.detached(_loggerName);
    _logger.level = _loggerLevel;
    _logger.onRecord.listen((event) {
      print(event);
    });
    this._pollingInterval = pollingInterval ?? Duration(seconds: 1);
  }

  Future<JanusSession> createSession() async {
    _logger.info("Creating Session");
    _logger.fine("fine message");
    JanusSession session = JanusSession(refreshInterval: _refreshInterval, transport: _transport, context: this);
    try {
      await session.create();
    } catch (e) {
      _logger.severe(e);
    }
    _logger.info("Session Created");
    return session;
  }
}
