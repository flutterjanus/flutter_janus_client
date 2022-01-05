import 'package:janus_client/JanusClient.dart';

class JanusVideoCallPlugin extends JanusPlugin {
  JanusVideoCallPlugin({handleId, context, transport, session}) : super(context: context,
      handleId: handleId,
      plugin: JanusPlugins.VIDEO_CALL,
      session: session,
      transport: transport);
}