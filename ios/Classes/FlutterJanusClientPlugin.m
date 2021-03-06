#import "FlutterJanusClientPlugin.h"
#if __has_include(<flutter_janus_client/flutter_janus_client-Swift.h>)
#import <flutter_janus_client/flutter_janus_client-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_janus_client-Swift.h"
#endif

@implementation FlutterJanusClientPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterJanusClientPlugin registerWithRegistrar:registrar];
}
@end
