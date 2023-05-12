// {
//     "event": "hangup",
//     "code": 200,
//     "reason": "Session Terminated",
//     "reason_header_protocol": "Q.850",
//     "reason_header_cause": "16"
// }
part of janus_client;

class SipHangupEvent {
  String? event;
  int? code;
  String? reason;
  String? reasonHeaderProtocol;
  String? reasonHeaderCause;

  SipHangupEvent({this.event, this.code, this.reason, this.reasonHeaderProtocol, this.reasonHeaderCause});

  SipHangupEvent.fromJson(Map<String, dynamic> json) {
    this.event = json["event"];
    this.code = json["code"];
    this.reason = json["reason"];
    this.reasonHeaderProtocol = json["reason_header_protocol"];
    this.reasonHeaderCause = json["reason_header_cause"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["event"] = this.event;
    data["code"] = this.code;
    data["reason"] = this.reason;
    data["reason_header_protocol"] = this.reasonHeaderProtocol;
    data["reason_header_cause"] = this.reasonHeaderCause;
    return data;
  }
}
