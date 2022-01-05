import 'package:janus_client/JanusClient.dart';

class JanusSipPlugin extends JanusPlugin {
  JanusSipPlugin({handleId, context, transport, session}) : super(context: context,
      handleId: handleId,
      plugin: JanusPlugins.SIP,
      session: session,
      transport: transport);
}