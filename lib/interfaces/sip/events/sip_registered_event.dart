part of janus_client;

class SipRegisteredEvent {
  String? sip;
  SipRegisteredEventResult? result;

  SipRegisteredEvent({this.sip, this.result});

  SipRegisteredEvent.fromJson(Map<String, dynamic> json) {
    this.sip = json["sip"];
    this.result = json["result"] == null ? null : SipRegisteredEventResult.fromJson(json["result"]);
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
  bool? registerSent;
  int? masterId;

  SipRegisteredEventResult({this.event, this.username, this.registerSent, this.masterId});

  SipRegisteredEventResult.fromJson(Map<String, dynamic> json) {
    this.event = json["event"] as String?;
    this.username = json["username"] as String?;
    this.registerSent = json["register_sent"] as bool?;
    this.masterId = json["master_id"] as int?;
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
