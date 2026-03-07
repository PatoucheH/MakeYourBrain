// iOS 26 workaround: pure Objective-C implementation of shared_preferences_foundation.
// The Swift-based plugin (2.5.6) crashes on iOS 26 in swift_getObjectType during
// plugin registration. Pure ObjC avoids the Swift type metadata system entirely.

#import "SharedPreferencesPlugin.h"

// ─── Legacy implementation ────────────────────────────────────────────────────

@interface LegacySharedPreferencesPlugin : NSObject <FlutterPlugin>
@end

@implementation LegacySharedPreferencesPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/shared_preferences_foundation"
                                 binaryMessenger:[registrar messenger]];
  LegacySharedPreferencesPlugin *instance = [[LegacySharedPreferencesPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSDictionary *args = call.arguments;

  if ([call.method isEqualToString:@"getAll"]) {
    NSString *prefix = args[@"prefix"] ?: @"flutter.";
    NSArray *allowList = args[@"allowList"];
    NSMutableDictionary *filtered = [NSMutableDictionary dictionary];
    NSDictionary *all = [defaults dictionaryRepresentation];
    for (NSString *key in all) {
      if ([key hasPrefix:prefix]) {
        if (!allowList || [allowList containsObject:key]) {
          filtered[key] = all[key];
        }
      }
    }
    result(filtered);

  } else if ([call.method isEqualToString:@"setBool"]) {
    [defaults setBool:[args[@"value"] boolValue] forKey:args[@"key"]];
    result(@YES);

  } else if ([call.method isEqualToString:@"setInt"]) {
    [defaults setInteger:[args[@"value"] integerValue] forKey:args[@"key"]];
    result(@YES);

  } else if ([call.method isEqualToString:@"setDouble"]) {
    [defaults setDouble:[args[@"value"] doubleValue] forKey:args[@"key"]];
    result(@YES);

  } else if ([call.method isEqualToString:@"setString"]) {
    [defaults setObject:args[@"value"] forKey:args[@"key"]];
    result(@YES);

  } else if ([call.method isEqualToString:@"setStringList"]) {
    [defaults setObject:args[@"value"] forKey:args[@"key"]];
    result(@YES);

  } else if ([call.method isEqualToString:@"remove"]) {
    [defaults removeObjectForKey:args[@"key"]];
    result(@YES);

  } else if ([call.method isEqualToString:@"clear"]) {
    NSString *prefix = args[@"prefix"] ?: @"flutter.";
    NSArray *allowList = args[@"allowList"];
    NSDictionary *all = [defaults dictionaryRepresentation];
    for (NSString *key in all) {
      if ([key hasPrefix:prefix]) {
        if (!allowList || ![allowList containsObject:key]) {
          [defaults removeObjectForKey:key];
        }
      }
    }
    result(@YES);

  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end

// ─── Entry point (delegates to legacy ObjC implementation) ───────────────────

@implementation SharedPreferencesPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [LegacySharedPreferencesPlugin registerWithRegistrar:registrar];
}

@end
