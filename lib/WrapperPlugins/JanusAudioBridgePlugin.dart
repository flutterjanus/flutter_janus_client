import 'package:janus_client/JanusClient.dart';

class JanusAudioBridgePlugin extends JanusPlugin {
  JanusAudioBridgePlugin({handleId, context, transport, session}) : super(context: context, handleId: handleId, plugin: JanusPlugins.AUDIO_BRIDGE, session: session, transport: transport);

  Future<void> joinRoom(int roomId,
      {String? id,
      String? group,
      String? pin,
      String? display,
      String? token,
      bool? muted,
      String? codec,
      String? preBuffer,
      int? quality,
      int? volume,
      int? spatialPosition,
      String? secret,
      String? audioLevelAverage,
      String? audioActivePackets,
      bool? record,
      String? filename}) async {
    Map<String, dynamic> payload = {
      "request": "join",
      "room": roomId,
      if (id != null) "id": id,
      if (group != null) "group": group,
      if (pin != null) "pin": pin,
      if (display != null) "display": display,
      if (token != null) "token": token,
      if (muted != null) "muted": muted,
      if (codec != null) "codec": codec,
      if (preBuffer != null) "prebuffer": preBuffer,
      if (quality != null) "quality": quality,
      if (volume != null) "volume": volume,
      if (spatialPosition != null) "spatial_position": spatialPosition,
      if (secret != null) "secret": secret,
      if (audioLevelAverage != null) "audio_level_average": audioLevelAverage,
      if (audioActivePackets != null) "audio_active_packets": audioActivePackets,
      if (record != null) "record": record,
      if (filename != null) "filename": filename
    };
    Map data = await this.send(data: payload);
  }
}
