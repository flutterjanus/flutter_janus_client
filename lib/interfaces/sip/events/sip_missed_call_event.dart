part of janus_client;

class SipMissedCallEvent {
  String? sip;
  String? callId;
  SipMissedCallEventResult? result;

  SipMissedCallEvent({this.sip, this.callId, this.result});

  SipMissedCallEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.callId = json["call_id"];
    this.result = json["result"] == null ? null : SipMissedCallEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    data["call_id"] = this.callId;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipMissedCallEventResult {
  String? event;
  String? caller;
  String? displayname;
  String? callee;

  SipMissedCallEventResult({this.event, this.caller, this.displayname, this.callee});

  SipMissedCallEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.caller = json["caller"];
    this.displayname = json["displayname"];
    this.callee = json["callee"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["caller"] = this.caller;
    data["displayname"] = this.displayname;
    data["callee"] = this.callee;
    return data;
  }
}
