#import "JanusClientPlugin.h"
#if __has_include(<janus_client/janus_client-Swift.h>)
#import <janus_client/janus_client-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "janus_client-Swift.h"
#endif

@implementation JanusClientPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftJanusClientPlugin registerWithRegistrar:registrar];
}
@end
