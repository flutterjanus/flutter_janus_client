part of janus_client;

class VideoRoomListResponse {
  VideoRoomListResponse({
    String? videoroom,
    List<JanusVideoRoom>? list,
  }) {
    _videoroom = videoroom;
    _list = list;
  }

  VideoRoomListResponse.fromJson(dynamic json) {
    _videoroom = json['videoroom'];
    if (json['list'] != null) {
      _list = [];
      json['list'].forEach((v) {
        _list?.add(JanusVideoRoom.fromJson(v));
      });
    }
  }
  String? _videoroom;
  List<JanusVideoRoom>? _list;

  String? get videoroom => _videoroom;
  List<JanusVideoRoom>? get list => _list;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['videoroom'] = _videoroom;
    if (_list != null) {
      map['list'] = _list?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// room : 1234
/// description : "<Name of the room>"
/// pin_required : false
/// is_private : false
/// max_publishers : 20
/// bitrate : 12444
/// bitrate_cap : 3
/// fir_freq : 35
/// require_pvtid : false
/// require_e2ee : false
/// notify_joining : false
/// audiocodec : ""
/// videocodec : ""
/// opus_fec : false
/// video_svc : false
/// record : false
/// rec_dir : ""
/// lock_record : false
/// num_participants : 20
/// audiolevel_ext : false
/// audiolevel_event : true
/// audio_active_packets : 200
/// audio_level_average : 200
/// videoorient_ext : false
/// playoutdelay_ext : false
/// transport_wide_cc_ext : false

class JanusVideoRoom {
  JanusVideoRoom({
    dynamic room,
    String? description,
    bool? pinRequired,
    bool? isPrivate,
    int? maxPublishers,
    int? bitrate,
    int? bitrateCap,
    int? firFreq,
    bool? requirePvtid,
    bool? requireE2ee,
    bool? notifyJoining,
    String? audiocodec,
    String? videocodec,
    bool? opusFec,
    bool? videoSvc,
    bool? record,
    String? recDir,
    bool? lockRecord,
    int? numParticipants,
    bool? audiolevelExt,
    bool? audiolevelEvent,
    int? audioActivePackets,
    int? audioLevelAverage,
    bool? videoorientExt,
    bool? playoutdelayExt,
    bool? transportWideCcExt,
  }) {
    _room = room;
    _description = description;
    _pinRequired = pinRequired;
    _isPrivate = isPrivate;
    _maxPublishers = maxPublishers;
    _bitrate = bitrate;
    _bitrateCap = bitrateCap;
    _firFreq = firFreq;
    _requirePvtid = requirePvtid;
    _requireE2ee = requireE2ee;
    _notifyJoining = notifyJoining;
    _audiocodec = audiocodec;
    _videocodec = videocodec;
    _opusFec = opusFec;
    _videoSvc = videoSvc;
    _record = record;
    _recDir = recDir;
    _lockRecord = lockRecord;
    _numParticipants = numParticipants;
    _audiolevelExt = audiolevelExt;
    _audiolevelEvent = audiolevelEvent;
    _audioActivePackets = audioActivePackets;
    _audioLevelAverage = audioLevelAverage;
    _videoorientExt = videoorientExt;
    _playoutdelayExt = playoutdelayExt;
    _transportWideCcExt = transportWideCcExt;
  }

  JanusVideoRoom.fromJson(dynamic json) {
    _room = json['room'];
    _description = json['description'];
    _pinRequired = json['pin_required'];
    _isPrivate = json['is_private'];
    _maxPublishers = json['max_publishers'];
    _bitrate = json['bitrate'];
    _bitrateCap = json['bitrate_cap'];
    _firFreq = json['fir_freq'];
    _requirePvtid = json['require_pvtid'];
    _requireE2ee = json['require_e2ee'];
    _notifyJoining = json['notify_joining'];
    _audiocodec = json['audiocodec'];
    _videocodec = json['videocodec'];
    _opusFec = json['opus_fec'];
    _videoSvc = json['video_svc'];
    _record = json['record'];
    _recDir = json['rec_dir'];
    _lockRecord = json['lock_record'];
    _numParticipants = json['num_participants'];
    _audiolevelExt = json['audiolevel_ext'];
    _audiolevelEvent = json['audiolevel_event'];
    _audioActivePackets = json['audio_active_packets'];
    _audioLevelAverage = json['audio_level_average'];
    _videoorientExt = json['videoorient_ext'];
    _playoutdelayExt = json['playoutdelay_ext'];
    _transportWideCcExt = json['transport_wide_cc_ext'];
  }
  dynamic _room;
  String? _description;
  bool? _pinRequired;
  bool? _isPrivate;
  int? _maxPublishers;
  int? _bitrate;
  int? _bitrateCap;
  int? _firFreq;
  bool? _requirePvtid;
  bool? _requireE2ee;
  bool? _notifyJoining;
  String? _audiocodec;
  String? _videocodec;
  bool? _opusFec;
  bool? _videoSvc;
  bool? _record;
  String? _recDir;
  bool? _lockRecord;
  int? _numParticipants;
  bool? _audiolevelExt;
  bool? _audiolevelEvent;
  int? _audioActivePackets;
  int? _audioLevelAverage;
  bool? _videoorientExt;
  bool? _playoutdelayExt;
  bool? _transportWideCcExt;

  int? get room => _room;
  String? get description => _description;
  bool? get pinRequired => _pinRequired;
  bool? get isPrivate => _isPrivate;
  int? get maxPublishers => _maxPublishers;
  int? get bitrate => _bitrate;
  int? get bitrateCap => _bitrateCap;
  int? get firFreq => _firFreq;
  bool? get requirePvtid => _requirePvtid;
  bool? get requireE2ee => _requireE2ee;
  bool? get notifyJoining => _notifyJoining;
  String? get audiocodec => _audiocodec;
  String? get videocodec => _videocodec;
  bool? get opusFec => _opusFec;
  bool? get videoSvc => _videoSvc;
  bool? get record => _record;
  String? get recDir => _recDir;
  bool? get lockRecord => _lockRecord;
  int? get numParticipants => _numParticipants;
  bool? get audiolevelExt => _audiolevelExt;
  bool? get audiolevelEvent => _audiolevelEvent;
  int? get audioActivePackets => _audioActivePackets;
  int? get audioLevelAverage => _audioLevelAverage;
  bool? get videoorientExt => _videoorientExt;
  bool? get playoutdelayExt => _playoutdelayExt;
  bool? get transportWideCcExt => _transportWideCcExt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['room'] = _room;
    map['description'] = _description;
    map['pin_required'] = _pinRequired;
    map['is_private'] = _isPrivate;
    map['max_publishers'] = _maxPublishers;
    map['bitrate'] = _bitrate;
    map['bitrate_cap'] = _bitrateCap;
    map['fir_freq'] = _firFreq;
    map['require_pvtid'] = _requirePvtid;
    map['require_e2ee'] = _requireE2ee;
    map['notify_joining'] = _notifyJoining;
    map['audiocodec'] = _audiocodec;
    map['videocodec'] = _videocodec;
    map['opus_fec'] = _opusFec;
    map['video_svc'] = _videoSvc;
    map['record'] = _record;
    map['rec_dir'] = _recDir;
    map['lock_record'] = _lockRecord;
    map['num_participants'] = _numParticipants;
    map['audiolevel_ext'] = _audiolevelExt;
    map['audiolevel_event'] = _audiolevelEvent;
    map['audio_active_packets'] = _audioActivePackets;
    map['audio_level_average'] = _audioLevelAverage;
    map['videoorient_ext'] = _videoorientExt;
    map['playoutdelay_ext'] = _playoutdelayExt;
    map['transport_wide_cc_ext'] = _transportWideCcExt;
    return map;
  }
}
