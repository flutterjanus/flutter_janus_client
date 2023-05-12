part of janus_client;

class SipUnRegisteredEvent {
  String? sip;
  SipUnRegisteredEventResult? result;

  SipUnRegisteredEvent({this.sip, this.result});

  SipUnRegisteredEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.result = json["result"] == null ? null : SipUnRegisteredEventResult.fromJson(json["result"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["sip"] = this.sip;
    if (this.result != null) data["result"] = this.result?.toJson();
    return data;
  }
}

class SipUnRegisteredEventResult {
  String? event;
  String? username;
  bool? registerSent;

  SipUnRegisteredEventResult({this.event, this.username, this.registerSent});

  SipUnRegisteredEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.username = json["username"];
    this.registerSent = json["register_sent"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["username"] = this.username;
    data["register_sent"] = this.registerSent;
    return data;
  }
}
