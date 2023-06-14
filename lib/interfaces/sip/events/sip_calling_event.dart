part of janus_client;

class SipCallingEvent {
  String? sip;
  String? callId;
  SipCallingEventResult? result;

  SipCallingEvent({this.sip, this.callId, this.result});

  SipCallingEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.callId = json["call_id"];
    this.result = json["result"] == null ? null : SipCallingEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    data["call_id"] = this.callId;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipCallingEventResult {
  String? event;
  String? callId;

  SipCallingEventResult({this.event, this.callId});

  SipCallingEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.callId = json["call_id"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["call_id"] = this.callId;
    return data;
  }
}
