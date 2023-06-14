part of janus_client;

class SipIncomingCallEvent {
  String? sip;
  String? callId;
  SipIncomingCallEventResult? result;

  SipIncomingCallEvent({this.sip, this.callId, this.result});

  SipIncomingCallEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.callId = json["call_id"];
    this.result = json["result"] == null ? null : SipIncomingCallEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    data["call_id"] = this.callId;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipIncomingCallEventResult {
  String? event;
  String? username;
  String? displayname;
  String? callee;
  String? referredBy;
  String? replaces;
  String? srtp;
  String? headers;

  SipIncomingCallEventResult({this.event, this.username, this.displayname, this.callee, this.referredBy, this.replaces, this.srtp, this.headers});

  SipIncomingCallEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.username = json["username"];
    this.displayname = json["displayname"];
    this.callee = json["callee"];
    this.referredBy = json["referred_by"];
    this.replaces = json["replaces"];
    this.srtp = json["srtp"];
    this.headers = json["headers"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["username"] = this.username;
    data["displayname"] = this.displayname;
    data["callee"] = this.callee;
    data["referred_by"] = this.referredBy;
    data["replaces"] = this.replaces;
    data["srtp"] = this.srtp;
    data["headers"] = this.headers;
    return data;
  }
}
