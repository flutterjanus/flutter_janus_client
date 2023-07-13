/// This is a preliminary API providing most WebRTC Operations out of the box using [Janus Server](https://janus.conf.meetecho.com/)
library janus_client;

import 'package:flutter/foundation.dart';
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

part './interfaces/janus_client.dart';

part './interfaces/text_room/text_room.dart';

part 'janus_session.dart';

part 'janus_transport.dart';

part 'janus_plugin.dart';

part './utils.dart';

part './wrapper_plugins/janus_video_call_plugin.dart';

part './wrapper_plugins/janus_sip_plugin.dart';

part './wrapper_plugins/janus_video_room_plugin.dart';

part 'interfaces/typed_event.dart';

part './wrapper_plugins/janus_audio_bridge_plugin.dart';

part './wrapper_plugins/janus_streaming_plugin.dart';

part './wrapper_plugins/janus_text_room_plugin.dart';

part './wrapper_plugins/janus_echo_test_plugin.dart';

part './interfaces/video_room/video_room_list_response.dart';

part './interfaces/video_room/video_room_list_participants_response.dart';

part './interfaces/video_room/events/video_room_atached_event.dart';

part './interfaces/video_room/events/video_room_configured.dart';

part './interfaces/video_room/events/video_room_joined_event.dart';

part './interfaces/video_room/events/video_room_updated_event.dart';

part './interfaces/video_room/events/video_room_leaving_event.dart';

part './interfaces/video_room/events/video_room_unpublished_event.dart';

part './interfaces/video_room/events/video_room_new_publisher_event.dart';

part './interfaces/video_room/events/video_room_event.dart';

part './interfaces/video_call/events/video_call_accepted_event.dart';

part './interfaces/video_call/events/video_call_calling_event.dart';

part './interfaces/video_call/events/video_call_event.dart';

part './interfaces/video_call/events/video_call_hangup_event.dart';

part './interfaces/video_call/events/video_call_incoming_call_event.dart';

part './interfaces/video_call/events/video_call_registered_event.dart';

part './interfaces/streaming/create_media_item.dart';

part './interfaces/streaming/streaming_mount.dart';

part './interfaces/streaming/streaming_mount_edited.dart';

part './interfaces/streaming/streaming_mount_point.dart';

part './interfaces/streaming/streaming_mount_point_info.dart';

part './interfaces/streaming/events/streaming_plugin_preparing_event.dart';

part './interfaces/streaming/events/streaming_plugin_stopping_event.dart';

part './interfaces/audio_bridge/audio_room_created_response.dart';

part './interfaces/audio_bridge/rtp_forward_stopped.dart';

part './interfaces/audio_bridge/rtp_forwarder_created.dart';

part './interfaces/audio_bridge/events/audio_bridge_configured_event.dart';

part './interfaces/audio_bridge/events/audio_bridge_event.dart';

part './interfaces/audio_bridge/events/audio_bridge_talking_event.dart';

part './interfaces/audio_bridge/events/audio_bridge_destroyed_event.dart';

part './interfaces/audio_bridge/events/audio_bridge_joined_event.dart';

part './interfaces/audio_bridge/events/audio_bridge_leaving_event.dart';

part './interfaces/sip/events/sip_registered_event.dart';

part './interfaces/sip/events/sip_accepted_event.dart';

part './interfaces/sip/events/sip_incoming_call_event.dart';

part './interfaces/sip/events/sip_missed_call_event.dart';

part './interfaces/sip/events/sip_progress_event.dart';

part './interfaces/sip/events/sip_ringing_event.dart';

part './interfaces/sip/events/sip_transfer_call_event.dart';

part './interfaces/sip/events/sip_unregistered_event.dart';

part './interfaces/sip/events/sip_hangup_event.dart';

part './interfaces/sip/events/sip_proceeding_event.dart';

part './interfaces/sip/events/sip_calling_event.dart';

class JanusClient {
  late JanusTransport _transport;
  String? _apiSecret;
  String? _token;
  late Duration _pollingInterval;
  late bool _withCredentials;
  late int? _maxEvent;
  late List<RTCIceServer>? _iceServers = [];
  late int _refreshInterval;
  late bool _isUnifiedPlan;
  late String _loggerName;
  late bool _usePlanB;
  late Logger _logger;
  late Level _loggerLevel;
  bool? _stringIds;

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
  /// setting usePlanB forces creation of peer connection with plan-b sdp semantics,
  /// and would cause isUnifiedPlan to have no effect on sdpSemantics config
  /// By default roomId should be numeric in nature although if you have configured [stringIds] to true for room or janus, then you can have non-numeric roomIds.
  JanusClient(
      {required JanusTransport transport,
      List<RTCIceServer>? iceServers,
      int refreshInterval = 50,
      String? apiSecret,
      bool isUnifiedPlan = true,
      String? token,
      bool? stringIds = false,
      /// if you provide your own logger you will be responsible for managing all logging aspects and properties like log level and printing logs
      Logger? logger,
      /// forces creation of peer connection with plan-b sdb semantics
      @Deprecated('set this option to true if you using legacy janus plugins with no unified-plan support only.') bool usePlanB = false,
      Duration? pollingInterval,
      String loggerName = "JanusClient",
      Level loggerLevel = Level.ALL,
      int maxEvent = 10,
      bool withCredentials = false}) {
    _stringIds = stringIds;
    _transport = transport;
    _isUnifiedPlan = isUnifiedPlan;
    _iceServers = iceServers;
    _refreshInterval = refreshInterval;
    _apiSecret = apiSecret;
    _maxEvent = maxEvent;
    _loggerLevel = loggerLevel;
    _withCredentials = withCredentials;
    _isUnifiedPlan = isUnifiedPlan;
    _token = token;
    _pollingInterval = pollingInterval ?? Duration(seconds: 1);
    _usePlanB = usePlanB;
    this._pollingInterval = pollingInterval ?? Duration(seconds: 1);
    if (logger == null) {
      _logger = Logger.detached(loggerName);
      _loggerName = loggerName;
      _logger.level = _loggerLevel;
      _logger.onRecord.listen((event) {
        print(event);
      });
    } else {
      _logger = logger;
    }
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

  /// Get janus server verbose information more like found on path `/info`
  Future<JanusClientInfo> getInfo() async {
    return JanusClientInfo.fromJson(await _transport.getInfo());
  }
}
