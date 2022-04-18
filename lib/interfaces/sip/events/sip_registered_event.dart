class SipRegisteredEvent {
  String? sip;
  SipRegisteredEventResult? result;

  SipRegisteredEvent({this.sip, this.result});

  SipRegisteredEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.result = json["result"] == null
        ? null
        : SipRegisteredEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipRegisteredEventResult {
  String? event;
  String? username;
  String? registerSent;
  String? masterId;

  SipRegisteredEventResult(
      {this.event, this.username, this.registerSent, this.masterId});

  SipRegisteredEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.username = json["username"];
    this.registerSent = json["register_sent"];
    this.masterId = json["master_id"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["username"] = this.username;
    data["register_sent"] = this.registerSent;
    data["master_id"] = this.masterId;
    return data;
  }
}
