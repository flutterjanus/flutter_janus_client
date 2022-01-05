import 'package:janus_client/JanusClient.dart';

class JanusEchoTestPlugin extends JanusPlugin {
  JanusEchoTestPlugin({handleId, context, transport, session}) : super(context: context,
      handleId: handleId,
      plugin: JanusPlugins.ECHO_TEST,
      session: session,
      transport: transport);
}