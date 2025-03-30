part of janus_client;

class JanusWebRTCHandle {
  MediaStream? remoteStream;
  MediaStream? localStream;
  RTCPeerConnection? peerConnection;
  Map<String, RTCDataChannel> dataChannel = {};

  JanusWebRTCHandle({
    this.peerConnection,
  });
}

class EventMessage {
  dynamic event;
  RTCSessionDescription? jsep;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  EventMessage({
    required this.event,
    required this.jsep,
  });

  EventMessage copyWith({
    dynamic event,
    RTCSessionDescription? jsep,
  }) {
    return new EventMessage(
      event: event ?? this.event,
      jsep: jsep ?? this.jsep,
    );
  }

  @override
  String toString() {
    return 'EventMessage{event: $event, jsep: $jsep}';
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is EventMessage && runtimeType == other.runtimeType && event == other.event && jsep == other.jsep);

  @override
  int get hashCode => event.hashCode ^ jsep.hashCode;

  factory EventMessage.fromMap(Map<String, dynamic> map) {
    return new EventMessage(
      event: map['event'] as dynamic,
      jsep: map['jsep'] as RTCSessionDescription?,
    );
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'event': this.event,
      'jsep': this.jsep,
    } as Map<String, dynamic>;
  }

//</editor-fold>
}

class RTCIceServer {
  String? username;
  String? credential;
  String? urls;

//<editor-fold desc="Data Methods">

  RTCIceServer({
    this.username,
    this.credential,
    this.urls,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is RTCIceServer && runtimeType == other.runtimeType && username == other.username && credential == other.credential && urls == other.urls);

  @override
  int get hashCode => username.hashCode ^ credential.hashCode ^ urls.hashCode;

  @override
  String toString() {
    return 'RTCIceServer{' + ' username: $username,' + ' credential: $credential,' + ' urls: $urls,' + '}';
  }

  RTCIceServer copyWith({
    String? username,
    String? credential,
    String? urls,
  }) {
    return RTCIceServer(
      username: username ?? this.username,
      credential: credential ?? this.credential,
      urls: urls ?? this.urls,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (username != null) 'username': this.username,
      if (credential != null) 'credential': this.credential,
      'urls': this.urls,
    };
  }

  factory RTCIceServer.fromMap(Map<String, dynamic> map) {
    return RTCIceServer(
      username: map['username'] as String,
      credential: map['credential'] as String,
      urls: map['urls'] as String,
    );
  }

//</editor-fold>
}

class RemoteTrack {
  MediaStream? stream;
  MediaStreamTrack? track;
  String? mid;
  bool? flowing;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  RemoteTrack({
    this.stream,
    required this.track,
    required this.mid,
    required this.flowing,
  });

  RemoteTrack copyWith({
    MediaStream? stream,
    MediaStreamTrack? track,
    String? mid,
    bool? flowing,
  }) {
    return new RemoteTrack(
      stream: stream ?? this.stream,
      track: track ?? this.track,
      mid: mid ?? this.mid,
      flowing: flowing ?? this.flowing,
    );
  }

  @override
  String toString() {
    return 'RemoteTrack{stream: $stream, track: $track, mid: $mid, flowing: $flowing}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteTrack && runtimeType == other.runtimeType && stream == other.stream && track == other.track && mid == other.mid && flowing == other.flowing);

  @override
  int get hashCode => stream.hashCode ^ track.hashCode ^ mid.hashCode ^ flowing.hashCode;

  factory RemoteTrack.fromMap(Map<String, dynamic> map) {
    return new RemoteTrack(
      stream: map['stream'] as MediaStream?,
      track: map['track'] as MediaStreamTrack?,
      mid: map['mid'] as String?,
      flowing: map['flowing'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'stream': this.stream,
      'track': this.track,
      'mid': this.mid,
      'flowing': this.flowing,
    } as Map<String, dynamic>;
  }

//</editor-fold>
}

Uuid getUuid() {
  return Uuid();
}

stringify(dynamic) {
  JsonEncoder encoder = JsonEncoder();
  return '${encoder.convert(dynamic)}';
}

parse(dynamic) {
  JsonDecoder jsonDecoder = JsonDecoder();
  if (dynamic == null || dynamic.toString().isEmpty) dynamic = "{}";
  return jsonDecoder.convert(dynamic);
}

String extractDomainFromUrl(String url) {
  if (url.startsWith('https://')) {
    url = url.substring('https://'.length);
  } else if (url.startsWith('http://')) {
    url = url.substring('http://'.length);
  }
  int pathIndex = url.indexOf('/');
  if (pathIndex != -1) {
    return url.substring(0, pathIndex);
  } else {
    return url;
  }
}

randomString({int len = 10, String charSet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#\$%^&*()_+'}) {
  var randomString = '';
  for (var i = 0; i < len; i++) {
    var randomPoz = (Math.Random().nextInt(charSet.length - 1)).floor();
    randomString += charSet.substring(randomPoz, randomPoz + 1);
  }
  return randomString + Timeline.now.toString();
}

Future<void> stopAllTracks(MediaStream? stream) async {
  for (MediaStreamTrack track in stream?.getTracks() ?? []) {
    await track.stop();
  }
}

Future<String> getCameraDeviceId(front) async {
  List<MediaDeviceInfo> videoDevices = (await navigator.mediaDevices.enumerateDevices()).where((element) => element.kind == 'videoinput').toList();
  if (videoDevices.isEmpty) {
    throw Exception("No camera found");
  }
  if (videoDevices.length == 1) {
    return videoDevices.first.deviceId;
  }
  return (front ? videoDevices.first.deviceId : videoDevices.last.deviceId);
}
