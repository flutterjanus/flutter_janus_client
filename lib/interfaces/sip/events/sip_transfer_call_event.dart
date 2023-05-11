part of janus_client;

class SipTransferCallEvent {
  String? sip;
  SipTransferCallEventResult? result;

  SipTransferCallEvent({this.sip, this.result});

  SipTransferCallEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.result = json["result"] == null ? null : SipTransferCallEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipTransferCallEventResult {
  String? event;
  int? referId;
  String? referTo;
  String? referredBy;
  String? replaces;
  String? headers;

  SipTransferCallEventResult({this.event, this.referId, this.referTo, this.referredBy, this.replaces, this.headers});

  SipTransferCallEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.referId = json["refer_id"];
    this.referTo = json["refer_to"];
    this.referredBy = json["referred_by"];
    this.replaces = json["replaces"];
    this.headers = json["headers"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["refer_id"] = this.referId;
    data["refer_to"] = this.referTo;
    data["referred_by"] = this.referredBy;
    data["replaces"] = this.replaces;
    data["headers"] = this.headers;
    return data;
  }
}
