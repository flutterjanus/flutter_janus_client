import 'package:janus_client/JanusClient.dart';

class JanusStreamingPlugin extends JanusPlugin {
  JanusStreamingPlugin({handleId, context, transport, session}) : super(context: context,
      handleId: handleId,
      plugin: JanusPlugins.STREAMING,
      session: session,
      transport: transport);
}