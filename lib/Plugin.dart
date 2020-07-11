import 'package:janus_client/PluginHandle.dart';

class Plugin {
  String plugin;
  String opaqueId;
  Function(PluginHandle) onSuccess;
  Function(dynamic) onError;
  Function(dynamic, dynamic) onMessage;
  Function(dynamic) onLocalStream;
  Function(dynamic) onRemoteStream;

  Plugin(
      {this.plugin,
      this.onSuccess,
      this.onError,
      this.onMessage,
      this.onLocalStream,
      this.onRemoteStream});
}
