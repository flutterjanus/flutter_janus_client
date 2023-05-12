part of janus_client;

class JanusClientInfo {
  JanusClientInfo({
    String? janus,
    String? transaction,
    String? name,
    int? version,
    String? versionString,
    String? author,
    String? commithash,
    String? compiletime,
    bool? logtostdout,
    bool? logtofile,
    bool? dataChannels,
    bool? acceptingnewsessions,
    int? sessiontimeout,
    int? reclaimsessiontimeout,
    int? candidatestimeout,
    String? servername,
    String? localip,
    bool? ipv6,
    bool? ipv6linklocal,
    bool? icelite,
    bool? icetcp,
    String? icenomination,
    bool? icekeepaliveconncheck,
    bool? fulltrickle,
    bool? mdnsenabled,
    int? minnackqueue,
    bool? nackoptimizations,
    int? twccperiod,
    int? dtlsmtu,
    int? staticeventloops,
    bool? loopindication,
    bool? apiSecret,
    bool? authToken,
    bool? eventHandlers,
    bool? opaqueidInApi,
    Dependencies? dependencies,
    Transports? transports,
    dynamic events,
    dynamic loggers,
    Plugins? plugins,
  }) {
    _janus = janus;
    _transaction = transaction;
    _name = name;
    _version = version;
    _versionString = versionString;
    _author = author;
    _commithash = commithash;
    _compiletime = compiletime;
    _logtostdout = logtostdout;
    _logtofile = logtofile;
    _dataChannels = dataChannels;
    _acceptingnewsessions = acceptingnewsessions;
    _sessiontimeout = sessiontimeout;
    _reclaimsessiontimeout = reclaimsessiontimeout;
    _candidatestimeout = candidatestimeout;
    _servername = servername;
    _localip = localip;
    _ipv6 = ipv6;
    _ipv6linklocal = ipv6linklocal;
    _icelite = icelite;
    _icetcp = icetcp;
    _icenomination = icenomination;
    _icekeepaliveconncheck = icekeepaliveconncheck;
    _fulltrickle = fulltrickle;
    _mdnsenabled = mdnsenabled;
    _minnackqueue = minnackqueue;
    _nackoptimizations = nackoptimizations;
    _twccperiod = twccperiod;
    _dtlsmtu = dtlsmtu;
    _staticeventloops = staticeventloops;
    _loopindication = loopindication;
    _apiSecret = apiSecret;
    _authToken = authToken;
    _eventHandlers = eventHandlers;
    _opaqueidInApi = opaqueidInApi;
    _dependencies = dependencies;
    _transports = transports;
    _events = events;
    _loggers = loggers;
    _plugins = plugins;
  }

  JanusClientInfo.fromJson(dynamic json) {
    _janus = json['janus'];
    _transaction = json['transaction'];
    _name = json['name'];
    _version = json['version'];
    _versionString = json['version_string'];
    _author = json['author'];
    _commithash = json['commit-hash'];
    _compiletime = json['compile-time'];
    _logtostdout = json['log-to-stdout'];
    _logtofile = json['log-to-file'];
    _dataChannels = json['data_channels'];
    _acceptingnewsessions = json['accepting-new-sessions'];
    _sessiontimeout = json['session-timeout'];
    _reclaimsessiontimeout = json['reclaim-session-timeout'];
    _candidatestimeout = json['candidates-timeout'];
    _servername = json['server-name'];
    _localip = json['local-ip'];
    _ipv6 = json['ipv6'];
    _ipv6linklocal = json['ipv6-link-local'];
    _icelite = json['ice-lite'];
    _icetcp = json['ice-tcp'];
    _icenomination = json['ice-nomination'];
    _icekeepaliveconncheck = json['ice-keepalive-conncheck'];
    _fulltrickle = json['full-trickle'];
    _mdnsenabled = json['mdns-enabled'];
    _minnackqueue = json['min-nack-queue'];
    _nackoptimizations = json['nack-optimizations'];
    _twccperiod = json['twcc-period'];
    _dtlsmtu = json['dtls-mtu'];
    _staticeventloops = json['static-event-loops'];
    _loopindication = json['loop-indication'];
    _apiSecret = json['api_secret'];
    _authToken = json['auth_token'];
    _eventHandlers = json['event_handlers'];
    _opaqueidInApi = json['opaqueid_in_api'];
    _dependencies = json['dependencies'] != null ? Dependencies.fromJson(json['dependencies']) : null;
    _transports = json['transports'] != null ? Transports.fromJson(json['transports']) : null;
    _events = json['events'];
    _loggers = json['loggers'];
    _plugins = json['plugins'] != null ? Plugins.fromJson(json['plugins']) : null;
  }

  String? _janus;
  String? _transaction;
  String? _name;
  int? _version;
  String? _versionString;
  String? _author;
  String? _commithash;
  String? _compiletime;
  bool? _logtostdout;
  bool? _logtofile;
  bool? _dataChannels;
  bool? _acceptingnewsessions;
  int? _sessiontimeout;
  int? _reclaimsessiontimeout;
  int? _candidatestimeout;
  String? _servername;
  String? _localip;
  bool? _ipv6;
  bool? _ipv6linklocal;
  bool? _icelite;
  bool? _icetcp;
  String? _icenomination;
  bool? _icekeepaliveconncheck;
  bool? _fulltrickle;
  bool? _mdnsenabled;
  int? _minnackqueue;
  bool? _nackoptimizations;
  int? _twccperiod;
  int? _dtlsmtu;
  int? _staticeventloops;
  bool? _loopindication;
  bool? _apiSecret;
  bool? _authToken;
  bool? _eventHandlers;
  bool? _opaqueidInApi;
  Dependencies? _dependencies;
  Transports? _transports;
  dynamic _events;
  dynamic _loggers;
  Plugins? _plugins;

  JanusClientInfo copyWith({
    String? janus,
    String? transaction,
    String? name,
    int? version,
    String? versionString,
    String? author,
    String? commithash,
    String? compiletime,
    bool? logtostdout,
    bool? logtofile,
    bool? dataChannels,
    bool? acceptingnewsessions,
    int? sessiontimeout,
    int? reclaimsessiontimeout,
    int? candidatestimeout,
    String? servername,
    String? localip,
    bool? ipv6,
    bool? ipv6linklocal,
    bool? icelite,
    bool? icetcp,
    String? icenomination,
    bool? icekeepaliveconncheck,
    bool? fulltrickle,
    bool? mdnsenabled,
    int? minnackqueue,
    bool? nackoptimizations,
    int? twccperiod,
    int? dtlsmtu,
    int? staticeventloops,
    bool? loopindication,
    bool? apiSecret,
    bool? authToken,
    bool? eventHandlers,
    bool? opaqueidInApi,
    Dependencies? dependencies,
    Transports? transports,
    dynamic events,
    dynamic loggers,
    Plugins? plugins,
  }) =>
      JanusClientInfo(
        janus: janus ?? _janus,
        transaction: transaction ?? _transaction,
        name: name ?? _name,
        version: version ?? _version,
        versionString: versionString ?? _versionString,
        author: author ?? _author,
        commithash: commithash ?? _commithash,
        compiletime: compiletime ?? _compiletime,
        logtostdout: logtostdout ?? _logtostdout,
        logtofile: logtofile ?? _logtofile,
        dataChannels: dataChannels ?? _dataChannels,
        acceptingnewsessions: acceptingnewsessions ?? _acceptingnewsessions,
        sessiontimeout: sessiontimeout ?? _sessiontimeout,
        reclaimsessiontimeout: reclaimsessiontimeout ?? _reclaimsessiontimeout,
        candidatestimeout: candidatestimeout ?? _candidatestimeout,
        servername: servername ?? _servername,
        localip: localip ?? _localip,
        ipv6: ipv6 ?? _ipv6,
        ipv6linklocal: ipv6linklocal ?? _ipv6linklocal,
        icelite: icelite ?? _icelite,
        icetcp: icetcp ?? _icetcp,
        icenomination: icenomination ?? _icenomination,
        icekeepaliveconncheck: icekeepaliveconncheck ?? _icekeepaliveconncheck,
        fulltrickle: fulltrickle ?? _fulltrickle,
        mdnsenabled: mdnsenabled ?? _mdnsenabled,
        minnackqueue: minnackqueue ?? _minnackqueue,
        nackoptimizations: nackoptimizations ?? _nackoptimizations,
        twccperiod: twccperiod ?? _twccperiod,
        dtlsmtu: dtlsmtu ?? _dtlsmtu,
        staticeventloops: staticeventloops ?? _staticeventloops,
        loopindication: loopindication ?? _loopindication,
        apiSecret: apiSecret ?? _apiSecret,
        authToken: authToken ?? _authToken,
        eventHandlers: eventHandlers ?? _eventHandlers,
        opaqueidInApi: opaqueidInApi ?? _opaqueidInApi,
        dependencies: dependencies ?? _dependencies,
        transports: transports ?? _transports,
        events: events ?? _events,
        loggers: loggers ?? _loggers,
        plugins: plugins ?? _plugins,
      );

  String? get janus => _janus;

  String? get transaction => _transaction;

  String? get name => _name;

  int? get version => _version;

  String? get versionString => _versionString;

  String? get author => _author;

  String? get commithash => _commithash;

  String? get compiletime => _compiletime;

  bool? get logtostdout => _logtostdout;

  bool? get logtofile => _logtofile;

  bool? get dataChannels => _dataChannels;

  bool? get acceptingnewsessions => _acceptingnewsessions;

  int? get sessiontimeout => _sessiontimeout;

  int? get reclaimsessiontimeout => _reclaimsessiontimeout;

  int? get candidatestimeout => _candidatestimeout;

  String? get servername => _servername;

  String? get localip => _localip;

  bool? get ipv6 => _ipv6;

  bool? get ipv6linklocal => _ipv6linklocal;

  bool? get icelite => _icelite;

  bool? get icetcp => _icetcp;

  String? get icenomination => _icenomination;

  bool? get icekeepaliveconncheck => _icekeepaliveconncheck;

  bool? get fulltrickle => _fulltrickle;

  bool? get mdnsenabled => _mdnsenabled;

  int? get minnackqueue => _minnackqueue;

  bool? get nackoptimizations => _nackoptimizations;

  int? get twccperiod => _twccperiod;

  int? get dtlsmtu => _dtlsmtu;

  int? get staticeventloops => _staticeventloops;

  bool? get loopindication => _loopindication;

  bool? get apiSecret => _apiSecret;

  bool? get authToken => _authToken;

  bool? get eventHandlers => _eventHandlers;

  bool? get opaqueidInApi => _opaqueidInApi;

  Dependencies? get dependencies => _dependencies;

  Transports? get transports => _transports;

  dynamic get events => _events;

  dynamic get loggers => _loggers;

  Plugins? get plugins => _plugins;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['janus'] = _janus;
    map['transaction'] = _transaction;
    map['name'] = _name;
    map['version'] = _version;
    map['version_string'] = _versionString;
    map['author'] = _author;
    map['commit-hash'] = _commithash;
    map['compile-time'] = _compiletime;
    map['log-to-stdout'] = _logtostdout;
    map['log-to-file'] = _logtofile;
    map['data_channels'] = _dataChannels;
    map['accepting-new-sessions'] = _acceptingnewsessions;
    map['session-timeout'] = _sessiontimeout;
    map['reclaim-session-timeout'] = _reclaimsessiontimeout;
    map['candidates-timeout'] = _candidatestimeout;
    map['server-name'] = _servername;
    map['local-ip'] = _localip;
    map['ipv6'] = _ipv6;
    map['ipv6-link-local'] = _ipv6linklocal;
    map['ice-lite'] = _icelite;
    map['ice-tcp'] = _icetcp;
    map['ice-nomination'] = _icenomination;
    map['ice-keepalive-conncheck'] = _icekeepaliveconncheck;
    map['full-trickle'] = _fulltrickle;
    map['mdns-enabled'] = _mdnsenabled;
    map['min-nack-queue'] = _minnackqueue;
    map['nack-optimizations'] = _nackoptimizations;
    map['twcc-period'] = _twccperiod;
    map['dtls-mtu'] = _dtlsmtu;
    map['static-event-loops'] = _staticeventloops;
    map['loop-indication'] = _loopindication;
    map['api_secret'] = _apiSecret;
    map['auth_token'] = _authToken;
    map['event_handlers'] = _eventHandlers;
    map['opaqueid_in_api'] = _opaqueidInApi;
    if (_dependencies != null) {
      map['dependencies'] = _dependencies?.toJson();
    }
    if (_transports != null) {
      map['transports'] = _transports?.toJson();
    }
    map['events'] = _events;
    map['loggers'] = _loggers;
    if (_plugins != null) {
      map['plugins'] = _plugins?.toJson();
    }
    return map;
  }
}

class Plugins {
  Plugins({
    JanusPluginAudiobridge? januspluginaudiobridge,
    JanusPluginRecordplay? januspluginrecordplay,
    JanusPluginTextroom? janusplugintextroom,
    JanusPluginNosip? januspluginnosip,
    JanusPluginVoicemail? januspluginvoicemail,
    JanusPluginSip? januspluginsip,
    JanusPluginVideocall? januspluginvideocall,
    JanusPluginStreaming? januspluginstreaming,
    JanusPluginEchotest? januspluginechotest,
    JanusPluginVideoroom? januspluginvideoroom,
  }) {
    _januspluginaudiobridge = januspluginaudiobridge;
    _januspluginrecordplay = januspluginrecordplay;
    _janusplugintextroom = janusplugintextroom;
    _januspluginnosip = januspluginnosip;
    _januspluginvoicemail = januspluginvoicemail;
    _januspluginsip = januspluginsip;
    _januspluginvideocall = januspluginvideocall;
    _januspluginstreaming = januspluginstreaming;
    _januspluginechotest = januspluginechotest;
    _januspluginvideoroom = januspluginvideoroom;
  }

  Plugins.fromJson(dynamic json) {
    _januspluginaudiobridge = json['janus.plugin.audiobridge'] != null ? JanusPluginAudiobridge.fromJson(json['janus.plugin.audiobridge']) : null;
    _januspluginrecordplay = json['janus.plugin.recordplay'] != null ? JanusPluginRecordplay.fromJson(json['janus.plugin.recordplay']) : null;
    _janusplugintextroom = json['janus.plugin.textroom'] != null ? JanusPluginTextroom.fromJson(json['janus.plugin.textroom']) : null;
    _januspluginnosip = json['janus.plugin.nosip'] != null ? JanusPluginNosip.fromJson(json['janus.plugin.nosip']) : null;
    _januspluginvoicemail = json['janus.plugin.voicemail'] != null ? JanusPluginVoicemail.fromJson(json['janus.plugin.voicemail']) : null;
    _januspluginsip = json['janus.plugin.sip'] != null ? JanusPluginSip.fromJson(json['janus.plugin.sip']) : null;
    _januspluginvideocall = json['janus.plugin.videocall'] != null ? JanusPluginVideocall.fromJson(json['janus.plugin.videocall']) : null;
    _januspluginstreaming = json['janus.plugin.streaming'] != null ? JanusPluginStreaming.fromJson(json['janus.plugin.streaming']) : null;
    _januspluginechotest = json['janus.plugin.echotest'] != null ? JanusPluginEchotest.fromJson(json['janus.plugin.echotest']) : null;
    _januspluginvideoroom = json['janus.plugin.videoroom'] != null ? JanusPluginVideoroom.fromJson(json['janus.plugin.videoroom']) : null;
  }

  JanusPluginAudiobridge? _januspluginaudiobridge;
  JanusPluginRecordplay? _januspluginrecordplay;
  JanusPluginTextroom? _janusplugintextroom;
  JanusPluginNosip? _januspluginnosip;
  JanusPluginVoicemail? _januspluginvoicemail;
  JanusPluginSip? _januspluginsip;
  JanusPluginVideocall? _januspluginvideocall;
  JanusPluginStreaming? _januspluginstreaming;
  JanusPluginEchotest? _januspluginechotest;
  JanusPluginVideoroom? _januspluginvideoroom;

  Plugins copyWith({
    JanusPluginAudiobridge? januspluginaudiobridge,
    JanusPluginRecordplay? januspluginrecordplay,
    JanusPluginTextroom? janusplugintextroom,
    JanusPluginNosip? januspluginnosip,
    JanusPluginVoicemail? januspluginvoicemail,
    JanusPluginSip? januspluginsip,
    JanusPluginVideocall? januspluginvideocall,
    JanusPluginStreaming? januspluginstreaming,
    JanusPluginEchotest? januspluginechotest,
    JanusPluginVideoroom? januspluginvideoroom,
  }) =>
      Plugins(
        januspluginaudiobridge: januspluginaudiobridge ?? _januspluginaudiobridge,
        januspluginrecordplay: januspluginrecordplay ?? _januspluginrecordplay,
        janusplugintextroom: janusplugintextroom ?? _janusplugintextroom,
        januspluginnosip: januspluginnosip ?? _januspluginnosip,
        januspluginvoicemail: januspluginvoicemail ?? _januspluginvoicemail,
        januspluginsip: januspluginsip ?? _januspluginsip,
        januspluginvideocall: januspluginvideocall ?? _januspluginvideocall,
        januspluginstreaming: januspluginstreaming ?? _januspluginstreaming,
        januspluginechotest: januspluginechotest ?? _januspluginechotest,
        januspluginvideoroom: januspluginvideoroom ?? _januspluginvideoroom,
      );

  JanusPluginAudiobridge? get januspluginaudiobridge => _januspluginaudiobridge;

  JanusPluginRecordplay? get januspluginrecordplay => _januspluginrecordplay;

  JanusPluginTextroom? get janusplugintextroom => _janusplugintextroom;

  JanusPluginNosip? get januspluginnosip => _januspluginnosip;

  JanusPluginVoicemail? get januspluginvoicemail => _januspluginvoicemail;

  JanusPluginSip? get januspluginsip => _januspluginsip;

  JanusPluginVideocall? get januspluginvideocall => _januspluginvideocall;

  JanusPluginStreaming? get januspluginstreaming => _januspluginstreaming;

  JanusPluginEchotest? get januspluginechotest => _januspluginechotest;

  JanusPluginVideoroom? get januspluginvideoroom => _januspluginvideoroom;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_januspluginaudiobridge != null) {
      map['janus.plugin.audiobridge'] = _januspluginaudiobridge?.toJson();
    }
    if (_januspluginrecordplay != null) {
      map['janus.plugin.recordplay'] = _januspluginrecordplay?.toJson();
    }
    if (_janusplugintextroom != null) {
      map['janus.plugin.textroom'] = _janusplugintextroom?.toJson();
    }
    if (_januspluginnosip != null) {
      map['janus.plugin.nosip'] = _januspluginnosip?.toJson();
    }
    if (_januspluginvoicemail != null) {
      map['janus.plugin.voicemail'] = _januspluginvoicemail?.toJson();
    }
    if (_januspluginsip != null) {
      map['janus.plugin.sip'] = _januspluginsip?.toJson();
    }
    if (_januspluginvideocall != null) {
      map['janus.plugin.videocall'] = _januspluginvideocall?.toJson();
    }
    if (_januspluginstreaming != null) {
      map['janus.plugin.streaming'] = _januspluginstreaming?.toJson();
    }
    if (_januspluginechotest != null) {
      map['janus.plugin.echotest'] = _januspluginechotest?.toJson();
    }
    if (_januspluginvideoroom != null) {
      map['janus.plugin.videoroom'] = _januspluginvideoroom?.toJson();
    }
    return map;
  }
}

class JanusPluginVideoroom {
  JanusPluginVideoroom({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginVideoroom.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginVideoroom copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginVideoroom(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginEchotest {
  JanusPluginEchotest({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginEchotest.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginEchotest copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginEchotest(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginStreaming {
  JanusPluginStreaming({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginStreaming.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginStreaming copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginStreaming(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginVideocall {
  JanusPluginVideocall({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginVideocall.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginVideocall copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginVideocall(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginSip {
  JanusPluginSip({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginSip.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginSip copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginSip(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginVoicemail {
  JanusPluginVoicemail({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginVoicemail.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginVoicemail copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginVoicemail(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginNosip {
  JanusPluginNosip({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginNosip.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginNosip copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginNosip(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginTextroom {
  JanusPluginTextroom({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginTextroom.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginTextroom copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginTextroom(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginRecordplay {
  JanusPluginRecordplay({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginRecordplay.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginRecordplay copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginRecordplay(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusPluginAudiobridge {
  JanusPluginAudiobridge({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusPluginAudiobridge.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusPluginAudiobridge copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusPluginAudiobridge(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class Transports {
  Transports({
    JanusTransportHttp? janustransporthttp,
    JanusTransportNanomsg? janustransportnanomsg,
    JanusTransportWebsockets? janustransportwebsockets,
  }) {
    _janustransporthttp = janustransporthttp;
    _janustransportnanomsg = janustransportnanomsg;
    _janustransportwebsockets = janustransportwebsockets;
  }

  Transports.fromJson(dynamic json) {
    _janustransporthttp = json['janus.transport.http'] != null ? JanusTransportHttp.fromJson(json['janus.transport.http']) : null;
    _janustransportnanomsg = json['janus.transport.nanomsg'] != null ? JanusTransportNanomsg.fromJson(json['janus.transport.nanomsg']) : null;
    _janustransportwebsockets = json['janus.transport.websockets'] != null ? JanusTransportWebsockets.fromJson(json['janus.transport.websockets']) : null;
  }

  JanusTransportHttp? _janustransporthttp;
  JanusTransportNanomsg? _janustransportnanomsg;
  JanusTransportWebsockets? _janustransportwebsockets;

  Transports copyWith({
    JanusTransportHttp? janustransporthttp,
    JanusTransportNanomsg? janustransportnanomsg,
    JanusTransportWebsockets? janustransportwebsockets,
  }) =>
      Transports(
        janustransporthttp: janustransporthttp ?? _janustransporthttp,
        janustransportnanomsg: janustransportnanomsg ?? _janustransportnanomsg,
        janustransportwebsockets: janustransportwebsockets ?? _janustransportwebsockets,
      );

  JanusTransportHttp? get janustransporthttp => _janustransporthttp;

  JanusTransportNanomsg? get janustransportnanomsg => _janustransportnanomsg;

  JanusTransportWebsockets? get janustransportwebsockets => _janustransportwebsockets;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_janustransporthttp != null) {
      map['janus.transport.http'] = _janustransporthttp?.toJson();
    }
    if (_janustransportnanomsg != null) {
      map['janus.transport.nanomsg'] = _janustransportnanomsg?.toJson();
    }
    if (_janustransportwebsockets != null) {
      map['janus.transport.websockets'] = _janustransportwebsockets?.toJson();
    }
    return map;
  }
}

class JanusTransportWebsockets {
  JanusTransportWebsockets({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusTransportWebsockets.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusTransportWebsockets copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusTransportWebsockets(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusTransportNanomsg {
  JanusTransportNanomsg({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusTransportNanomsg.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusTransportNanomsg copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusTransportNanomsg(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class JanusTransportHttp {
  JanusTransportHttp({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) {
    _name = name;
    _author = author;
    _description = description;
    _versionString = versionString;
    _version = version;
  }

  JanusTransportHttp.fromJson(dynamic json) {
    _name = json['name'];
    _author = json['author'];
    _description = json['description'];
    _versionString = json['version_string'];
    _version = json['version'];
  }

  String? _name;
  String? _author;
  String? _description;
  String? _versionString;
  int? _version;

  JanusTransportHttp copyWith({
    String? name,
    String? author,
    String? description,
    String? versionString,
    int? version,
  }) =>
      JanusTransportHttp(
        name: name ?? _name,
        author: author ?? _author,
        description: description ?? _description,
        versionString: versionString ?? _versionString,
        version: version ?? _version,
      );

  String? get name => _name;

  String? get author => _author;

  String? get description => _description;

  String? get versionString => _versionString;

  int? get version => _version;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['author'] = _author;
    map['description'] = _description;
    map['version_string'] = _versionString;
    map['version'] = _version;
    return map;
  }
}

class Dependencies {
  Dependencies({
    String? glib2,
    String? jansson,
    String? libnice,
    String? libsrtp,
    String? libcurl,
    String? crypto,
  }) {
    _glib2 = glib2;
    _jansson = jansson;
    _libnice = libnice;
    _libsrtp = libsrtp;
    _libcurl = libcurl;
    _crypto = crypto;
  }

  Dependencies.fromJson(dynamic json) {
    _glib2 = json['glib2'];
    _jansson = json['jansson'];
    _libnice = json['libnice'];
    _libsrtp = json['libsrtp'];
    _libcurl = json['libcurl'];
    _crypto = json['crypto'];
  }

  String? _glib2;
  String? _jansson;
  String? _libnice;
  String? _libsrtp;
  String? _libcurl;
  String? _crypto;

  Dependencies copyWith({
    String? glib2,
    String? jansson,
    String? libnice,
    String? libsrtp,
    String? libcurl,
    String? crypto,
  }) =>
      Dependencies(
        glib2: glib2 ?? _glib2,
        jansson: jansson ?? _jansson,
        libnice: libnice ?? _libnice,
        libsrtp: libsrtp ?? _libsrtp,
        libcurl: libcurl ?? _libcurl,
        crypto: crypto ?? _crypto,
      );

  String? get glib2 => _glib2;

  String? get jansson => _jansson;

  String? get libnice => _libnice;

  String? get libsrtp => _libsrtp;

  String? get libcurl => _libcurl;

  String? get crypto => _crypto;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['glib2'] = _glib2;
    map['jansson'] = _jansson;
    map['libnice'] = _libnice;
    map['libsrtp'] = _libsrtp;
    map['libcurl'] = _libcurl;
    map['crypto'] = _crypto;
    return map;
  }
}
