// iOS 26 workaround: pure Objective-C implementation of shared_preferences_foundation.
// The Swift-based plugin (2.5.6) crashes on iOS 26 in swift_getObjectType during
// plugin registration. Pure ObjC avoids the Swift type metadata system entirely.
//
// This implementation registers the Pigeon BasicMessageChannels that
// shared_preferences_foundation-2.5.6 uses on the Dart side (LegacyUserDefaultsApi
// and UserDefaultsApi). The old MethodChannel format is no longer used by 2.5.6.

#import "SharedPreferencesPlugin.h"

// ─── Pigeon channel helpers ───────────────────────────────────────────────────

// Success reply wrapping a single value (or NSNull for void).
static NSArray *SPSuccessVoid(void) { return @[[NSNull null]]; }
static NSArray *SPSuccessValue(id value) { return @[value ?: [NSNull null]]; }

// ─── Legacy UserDefaults API ──────────────────────────────────────────────────
// Channels: dev.flutter.pigeon.shared_preferences_foundation.LegacyUserDefaultsApi.*
// These use FlutterStandardMessageCodec (no custom types in args for legacy methods).

static void registerLegacyChannels(NSObject<FlutterPluginRegistrar> *registrar) {
    NSObject<FlutterBinaryMessenger> *messenger = [registrar messenger];
    FlutterStandardMessageCodec *codec = [FlutterStandardMessageCodec sharedInstance];

    static NSString *const kBase = @"dev.flutter.pigeon.shared_preferences_foundation.LegacyUserDefaultsApi.";

    // ── remove(String key) ────────────────────────────────────────────────────
    FlutterBasicMessageChannel *removeChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"remove"]
               binaryMessenger:messenger
                         codec:codec];
    [removeChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *key = args[0];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        reply(SPSuccessVoid());
    }];

    // ── setBool(String key, bool value) ───────────────────────────────────────
    FlutterBasicMessageChannel *setBoolChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"setBool"]
               binaryMessenger:messenger
                         codec:codec];
    [setBoolChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *key = args[0];
        BOOL value = [args[1] boolValue];
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
        reply(SPSuccessVoid());
    }];

    // ── setDouble(String key, double value) ───────────────────────────────────
    FlutterBasicMessageChannel *setDoubleChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"setDouble"]
               binaryMessenger:messenger
                         codec:codec];
    [setDoubleChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *key = args[0];
        double value = [args[1] doubleValue];
        [[NSUserDefaults standardUserDefaults] setDouble:value forKey:key];
        reply(SPSuccessVoid());
    }];

    // ── setValue(String key, Object value) ────────────────────────────────────
    // Used for int, String, and StringList (Dart passes raw value).
    FlutterBasicMessageChannel *setValueChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"setValue"]
               binaryMessenger:messenger
                         codec:codec];
    [setValueChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *key = args[0];
        id value = args[1];
        if (value == nil || [value isKindOfClass:[NSNull class]]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
        }
        reply(SPSuccessVoid());
    }];

    // ── getAll(String prefix, List<String>? allowList) ────────────────────────
    // Returns Map<String, Object> of matching keys.
    FlutterBasicMessageChannel *getAllChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"getAll"]
               binaryMessenger:messenger
                         codec:codec];
    [getAllChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *prefix = args[0];
        id rawAllowList = args[1];
        NSArray *allowList = ([rawAllowList isKindOfClass:[NSArray class]]) ? rawAllowList : nil;

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *all = [defaults dictionaryRepresentation];
        NSMutableDictionary *filtered = [NSMutableDictionary dictionary];
        for (NSString *key in all) {
            if ([key hasPrefix:prefix]) {
                if (!allowList || [allowList containsObject:key]) {
                    filtered[key] = all[key];
                }
            }
        }
        reply(SPSuccessValue(filtered));
    }];

    // ── clear(String prefix, List<String>? allowList) ─────────────────────────
    // Returns bool (always true on success).
    FlutterBasicMessageChannel *clearChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"clear"]
               binaryMessenger:messenger
                         codec:codec];
    [clearChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *prefix = args[0];
        id rawAllowList = args[1];
        NSArray *allowList = ([rawAllowList isKindOfClass:[NSArray class]]) ? rawAllowList : nil;

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *all = [defaults dictionaryRepresentation];
        for (NSString *key in all) {
            if ([key hasPrefix:prefix]) {
                // If allowList provided, only clear keys NOT in the list.
                if (!allowList || ![allowList containsObject:key]) {
                    [defaults removeObjectForKey:key];
                }
            }
        }
        reply(SPSuccessValue(@YES));
    }];
}

// ─── New UserDefaultsApi (async, with SharedPreferencesPigeonOptions) ─────────
// Channels: dev.flutter.pigeon.shared_preferences_foundation.UserDefaultsApi.*
// These include a SharedPreferencesPigeonOptions arg (custom type 129).
// We decode it with a custom reader/writer that strips type 129 into a plain array.

@interface SPPigeonWriter : FlutterStandardWriter
@end
@implementation SPPigeonWriter
- (void)writeValue:(id)value {
    // We never send type 129 back, so just use super.
    [super writeValue:value];
}
@end

@interface SPPigeonReader : FlutterStandardReader
@end
@implementation SPPigeonReader
- (id)readValueOfType:(UInt8)type {
    if (type == 129) {
        // SharedPreferencesPigeonOptions is encoded as [suiteName].
        // We decode it as a plain NSArray and treat it as opaque (we only need suiteName).
        return [self readValue];
    }
    return [super readValueOfType:type];
}
@end

@interface SPPigeonReaderWriter : FlutterStandardReaderWriter
@end
@implementation SPPigeonReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
    return [[SPPigeonWriter alloc] initWithData:data];
}
- (FlutterStandardReader *)readerWithData:(NSData *)data {
    return [[SPPigeonReader alloc] initWithData:data];
}
@end

@interface SPPigeonCodec : FlutterStandardMessageCodec
+ (instancetype)sharedInstance;
@end
@implementation SPPigeonCodec
+ (instancetype)sharedInstance {
    static SPPigeonCodec *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SPPigeonReaderWriter *rw = [[SPPigeonReaderWriter alloc] init];
        instance = (SPPigeonCodec *)[SPPigeonCodec codecWithReaderWriter:rw];
    });
    return instance;
}
@end

// Extract suiteName from options (decoded as NSArray [suiteName]).
static NSString *suiteNameFromOptions(id options) {
    if ([options isKindOfClass:[NSArray class]]) {
        NSArray *arr = (NSArray *)options;
        if (arr.count > 0 && [arr[0] isKindOfClass:[NSString class]]) {
            return arr[0];
        }
    }
    return nil;
}

static NSUserDefaults *defaultsForOptions(id options) {
    NSString *suiteName = suiteNameFromOptions(options);
    if (suiteName) {
        NSUserDefaults *suite = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        return suite ?: [NSUserDefaults standardUserDefaults];
    }
    return [NSUserDefaults standardUserDefaults];
}

static void registerUserDefaultsApiChannels(NSObject<FlutterPluginRegistrar> *registrar) {
    NSObject<FlutterBinaryMessenger> *messenger = [registrar messenger];
    SPPigeonCodec *codec = [SPPigeonCodec sharedInstance];

    static NSString *const kBase = @"dev.flutter.pigeon.shared_preferences_foundation.UserDefaultsApi.";

    // ── set(String key, Object value, Options options) ────────────────────────
    FlutterBasicMessageChannel *setChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"set"]
               binaryMessenger:messenger
                         codec:codec];
    [setChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *key = args[0];
        id value = args[1];
        id options = (args.count > 2) ? args[2] : nil;
        NSUserDefaults *defaults = defaultsForOptions(options);
        if (value == nil || [value isKindOfClass:[NSNull class]]) {
            [defaults removeObjectForKey:key];
        } else {
            [defaults setObject:value forKey:key];
        }
        reply(SPSuccessVoid());
    }];

    // ── clear(List<String>? allowList, Options options) ───────────────────────
    FlutterBasicMessageChannel *clearChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"clear"]
               binaryMessenger:messenger
                         codec:codec];
    [clearChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        id rawAllowList = args[0];
        id options = (args.count > 1) ? args[1] : nil;
        NSArray *allowList = ([rawAllowList isKindOfClass:[NSArray class]]) ? rawAllowList : nil;
        NSUserDefaults *defaults = defaultsForOptions(options);
        NSDictionary *all = [defaults dictionaryRepresentation];
        for (NSString *key in all) {
            if (!allowList || [allowList containsObject:key]) {
                [defaults removeObjectForKey:key];
            }
        }
        reply(SPSuccessVoid());
    }];

    // ── getAll(List<String>? allowList, Options options) ──────────────────────
    FlutterBasicMessageChannel *getAllChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"getAll"]
               binaryMessenger:messenger
                         codec:codec];
    [getAllChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        id rawAllowList = args[0];
        id options = (args.count > 1) ? args[1] : nil;
        NSArray *allowList = ([rawAllowList isKindOfClass:[NSArray class]]) ? rawAllowList : nil;
        NSUserDefaults *defaults = defaultsForOptions(options);
        NSDictionary *all = [defaults dictionaryRepresentation];
        NSMutableDictionary *filtered = [NSMutableDictionary dictionary];
        for (NSString *key in all) {
            if (!allowList || [allowList containsObject:key]) {
                filtered[key] = all[key];
            }
        }
        reply(SPSuccessValue(filtered));
    }];

    // ── getValue(String key, Options options) ─────────────────────────────────
    FlutterBasicMessageChannel *getValueChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"getValue"]
               binaryMessenger:messenger
                         codec:codec];
    [getValueChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *key = args[0];
        id options = (args.count > 1) ? args[1] : nil;
        NSUserDefaults *defaults = defaultsForOptions(options);
        id value = [defaults objectForKey:key];
        reply(SPSuccessValue(value));
    }];

    // ── getKeys(List<String>? allowList, Options options) ─────────────────────
    FlutterBasicMessageChannel *getKeysChannel = [FlutterBasicMessageChannel
        messageChannelWithName:[kBase stringByAppendingString:@"getKeys"]
               binaryMessenger:messenger
                         codec:codec];
    [getKeysChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        id rawAllowList = args[0];
        id options = (args.count > 1) ? args[1] : nil;
        NSArray *allowList = ([rawAllowList isKindOfClass:[NSArray class]]) ? rawAllowList : nil;
        NSUserDefaults *defaults = defaultsForOptions(options);
        NSDictionary *all = [defaults dictionaryRepresentation];
        NSMutableArray *keys = [NSMutableArray array];
        for (NSString *key in all) {
            if (!allowList || [allowList containsObject:key]) {
                [keys addObject:key];
            }
        }
        reply(SPSuccessValue(keys));
    }];
}

// ─── Entry point ──────────────────────────────────────────────────────────────

@implementation SharedPreferencesPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    registerLegacyChannels(registrar);
    registerUserDefaultsApiChannels(registrar);
}

@end
