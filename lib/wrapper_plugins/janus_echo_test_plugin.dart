part of janus_client;

class JanusEchoTestPlugin extends JanusPlugin {
  JanusEchoTestPlugin({handleId, context, transport, session})
      : super(context: context, handleId: handleId, plugin: JanusPlugins.ECHO_TEST, session: session, transport: transport);
}
