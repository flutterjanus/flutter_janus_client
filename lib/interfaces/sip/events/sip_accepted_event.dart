part of janus_client;

class SipAcceptedEvent {
  String? sip;
  String? callId;
  SipAcceptedEventResult? result;

  SipAcceptedEvent({this.sip, this.callId, this.result});

  SipAcceptedEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.callId = json["call_id"];
    this.result = json["result"] == null ? null : SipAcceptedEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    data["call_id"] = this.callId;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipAcceptedEventResult {
  String? event;
  String? username;
  String? headers;

  SipAcceptedEventResult({this.event, this.username, this.headers});

  SipAcceptedEventResult.fromJson(Map<String, dynamic> json) {
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
