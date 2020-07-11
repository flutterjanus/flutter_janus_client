import 'dart:convert';

class RTCIceServer {
  String username;
  String credentials;
  List<String> urls;
  RTCIceServer({this.urls, this.username, this.credentials});
}

stringify(dynamic) {
  JsonEncoder encoder = JsonEncoder();
  return '${encoder.convert(dynamic)}';
}

parse(dynamic) {
  JsonDecoder jsonDecoder = JsonDecoder();
  return jsonDecoder.convert(dynamic);
}
