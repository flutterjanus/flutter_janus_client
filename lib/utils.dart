import 'dart:convert';

class RTCIceServer {
  String username;
  String credentials;
  String urls;

//<editor-fold desc="Data Methods" defaultstate="collapsed">

  RTCIceServer({
    this.username,
    this.credentials,
    this.urls,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RTCIceServer &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          credentials == other.credentials &&
          urls == other.urls);

  @override
  int get hashCode => username.hashCode ^ credentials.hashCode ^ urls.hashCode;

  @override
  String toString() {
    return 'RTCIceServer{' +
        ' username: $username,' +
        ' credentials: $credentials,' +
        ' urls: $urls,' +
        '}';
  }

  Map<String, dynamic> toMap() {
    return {
      'username': this.username,
      'credentials': this.credentials,
      'urls': this.urls,
    };
  }

  factory RTCIceServer.fromMap(Map<String, dynamic> map) {
    return new RTCIceServer(
      username: map['username'] as String,
      credentials: map['credentials'] as String,
      urls: map['urls'] as String,
    );
  }

//</editor-fold>
}

stringify(dynamic) {
  JsonEncoder encoder = JsonEncoder();
  return '${encoder.convert(dynamic)}';
}

parse(dynamic) {
  JsonDecoder jsonDecoder = JsonDecoder();
  return jsonDecoder.convert(dynamic);
}
