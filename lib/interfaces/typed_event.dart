part of janus_client;

class TypedEvent<T> {
  T event;
  RTCSessionDescription? jsep;

//<editor-fold desc="Data Methods">

  TypedEvent({
    required this.event,
    this.jsep,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || (other is TypedEvent && runtimeType == other.runtimeType && event == other.event && jsep == other.jsep);

  @override
  int get hashCode => event.hashCode ^ jsep.hashCode;

  @override
  String toString() {
    return 'TypedEvent{' + ' event: $event,' + ' jsep: $jsep,' + '}';
  }

  TypedEvent copyWith({
    T? event,
    RTCSessionDescription? jsep,
  }) {
    return TypedEvent(
      event: event ?? this.event,
      jsep: jsep ?? this.jsep,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event': (this.event as dynamic).toMap(),
      'jsep': this.jsep,
    };
  }

  factory TypedEvent.fromMap(Map<String, dynamic> map) {
    return TypedEvent(
      event: map['event'] as T,
      jsep: map['jsep'] as RTCSessionDescription,
    );
  }

//</editor-fold>
}

class JanusEvent {
  JanusEvent({
    this.janus,
    this.sessionId,
    this.transaction,
    this.sender,
    this.plugindata,
  });

  JanusEvent.fromJson(dynamic json) {
    janus = json['janus'];
    sessionId = json['session_id'];
    transaction = json['transaction'];
    sender = json['sender'];
    plugindata = json['plugindata'] != null ? Plugindata.fromJson(json['plugindata']) : null;
  }

  String? janus;
  int? sessionId;
  String? transaction;
  int? sender;
  Plugindata? plugindata;

  @override
  String toString() {
    return 'JanusEvent{janus: $janus, sessionId: $sessionId, transaction: $transaction, sender: $sender, plugindata: $plugindata}';
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['janus'] = janus;
    map['session_id'] = sessionId;
    map['transaction'] = transaction;
    map['sender'] = sender;
    if (plugindata != null) {
      map['plugindata'] = plugindata?.toJson();
    }
    return map;
  }
}

class Plugindata {
  Plugindata({
    this.plugin,
    this.data,
  });

  @override
  String toString() {
    return 'Plugindata{plugin: $plugin, data: $data}';
  }

  Plugindata.fromJson(dynamic json) {
    plugin = json['plugin'];
    data = json['data'] != null ? json['data'] : null;
  }

  String? plugin;
  dynamic data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['plugin'] = plugin;
    if (data != null) {
      map['data'] = data;
    }
    return map;
  }
}

class JanusError {
  int errorCode;
  String error;
  String pluginName;
  String? event;

  static throwErrorFromEvent(JanusEvent response) {
    if (response.plugindata?.data != null && (response.plugindata?.data as Map).containsKey('error')) {
      throw JanusError.fromMap(response.plugindata?.data);
    }
  }

//<editor-fold desc="Data Methods">

  JanusError({
    required this.errorCode,
    required this.error,
    this.event,
    required this.pluginName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is JanusError && runtimeType == other.runtimeType && errorCode == other.errorCode && error == other.error && pluginName == other.pluginName);

  @override
  int get hashCode => errorCode.hashCode ^ error.hashCode ^ pluginName.hashCode;

  @override
  String toString() {
    return 'JanusError{' + ' error_code: $errorCode,' + ' error: $error,' + ' pluginName: $pluginName,' + ' event: $event,' + '}';
  }

  JanusError copyWith({
    int? errorCode,
    String? error,
    String? pluginName,
  }) {
    return JanusError(
      errorCode: errorCode ?? this.errorCode,
      error: error ?? this.error,
      pluginName: pluginName ?? this.pluginName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'error_code': this.errorCode,
      'error': this.error,
      'pluginName': this.pluginName,
    };
  }

  factory JanusError.fromMap(Map<String, dynamic> map) {
    if (map['result'] != null && map['result']?.containsKey('code') && map['result']?.containsKey('reason')) {
      return JanusError(
        event: map['result']?['event'] as String?,
        errorCode: map['result']?['code'] as int,
        error: map['result']?['reason'] as String,
        pluginName: map.entries.where((element) => element.value == 'event').first.key,
      );
    }
    return JanusError(
      errorCode: map['error_code'] as int,
      error: map['error'] as String,
      pluginName: map.entries.where((element) => element.value == 'event').first.key,
    );
  }

//</editor-fold>
}
