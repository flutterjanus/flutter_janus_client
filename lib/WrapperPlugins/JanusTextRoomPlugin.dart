part of janus_client;

class JanusTextRoomPlugin extends JanusPlugin {
  JanusTextRoomPlugin({handleId, context, transport, session}) : super(context: context,
      handleId: handleId,
      plugin: JanusPlugins.TEXT_ROOM,
      session: session,
      transport: transport);
}