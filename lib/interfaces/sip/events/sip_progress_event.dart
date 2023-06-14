part of janus_client;

class SipProgressEvent {
  String? sip;
  String? callId;
  SipProgressEventResult? result;

  SipProgressEvent({this.sip, this.callId, this.result});

  SipProgressEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.callId = json["call_id"];
    this.result = json["result"] == null ? null : SipProgressEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    data["call_id"] = this.callId;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipProgressEventResult {
  String? event;
  String? username;
  String? headers;

  SipProgressEventResult({this.event, this.username, this.headers});

  SipProgressEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.username = json["username"];
    this.headers = json["headers"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["username"] = this.username;
    data["headers"] = this.headers;
    return data;
  }
}
