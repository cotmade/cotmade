#import "GeneratedPluginRegistrant.h"
#import <cloud_firestore/CloudFirestorePlugin.h>  // Import the cloud_firestore plugin

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [CloudFirestorePlugin registerWithRegistrar:[registry registrarForPlugin:@"CloudFirestorePlugin"]];  // Register the plugin
}

@end

