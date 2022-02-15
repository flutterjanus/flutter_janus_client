part of janus_client;

class JanusSipPlugin extends JanusPlugin {
  JanusSipPlugin({handleId, context, transport, session}) : super(context: context, handleId: handleId, plugin: JanusPlugins.SIP, session: session, transport: transport);
}
