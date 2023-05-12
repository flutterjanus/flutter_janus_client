part of janus_client;

class SipProceedingEvent {
  String? sip;
  String? callId;
  SipProceedingEventResult? result;

  SipProceedingEvent({this.sip, this.callId, this.result});

  SipProceedingEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.callId = json["call_id"];
    this.result = json["result"] == null ? null : SipProceedingEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    data["call_id"] = this.callId;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipProceedingEventResult {
  String? event;
  int? code;

  SipProceedingEventResult({this.event, this.code});

  SipProceedingEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.code = json["code"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["code"] = this.code;
    return data;
  }
}
