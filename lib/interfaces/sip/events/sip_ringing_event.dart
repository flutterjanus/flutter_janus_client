part of janus_client;

class SipRingingEvent {
  String? sip;
  String? callId;
  SipRingingEventResult? result;

  SipRingingEvent({this.sip, this.callId, this.result});

  SipRingingEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.callId = json["call_id"];
    this.result = json["result"] == null ? null : SipRingingEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    data["call_id"] = this.callId;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipRingingEventResult {
  String? event;
  String? headers;

  SipRingingEventResult({this.event, this.headers});

  SipRingingEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.headers = json["headers"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["headers"] = this.headers;
    return data;
  }
}
