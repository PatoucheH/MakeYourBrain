// iOS 26 workaround: pure Objective-C implementation of url_launcher_ios.
// The Swift-based plugin crashes on iOS 26 in swift_getObjectType during
// plugin registration. Pure ObjC avoids the Swift type metadata system entirely.

#import "URLLauncherPlugin.h"
#import <UIKit/UIKit.h>

// ─── Enum values (matching Swift rawValue / Dart index) ──────────────────────

typedef NS_ENUM(NSInteger, URLLaunchResult) {
    URLLaunchResultSuccess   = 0,
    URLLaunchResultFailure   = 1,
    URLLaunchResultInvalidUrl = 2,
};

typedef NS_ENUM(NSInteger, URLInAppLoadResult) {
    URLInAppLoadResultSuccess       = 0,
    URLInAppLoadResultFailedToLoad  = 1,
    URLInAppLoadResultInvalidUrl    = 2,
    URLInAppLoadResultDismissed     = 3,
};

// ─── Wrapper objects for Pigeon custom-codec enum encoding ───────────────────

@interface URLLaunchResultWrapper : NSObject
@property (nonatomic) URLLaunchResult value;
+ (instancetype)wrap:(URLLaunchResult)value;
@end

@implementation URLLaunchResultWrapper
+ (instancetype)wrap:(URLLaunchResult)value {
    URLLaunchResultWrapper *w = [[URLLaunchResultWrapper alloc] init];
    w.value = value;
    return w;
}
@end

@interface URLInAppLoadResultWrapper : NSObject
@property (nonatomic) URLInAppLoadResult value;
+ (instancetype)wrap:(URLInAppLoadResult)value;
@end

@implementation URLInAppLoadResultWrapper
+ (instancetype)wrap:(URLInAppLoadResult)value {
    URLInAppLoadResultWrapper *w = [[URLInAppLoadResultWrapper alloc] init];
    w.value = value;
    return w;
}
@end

// ─── Custom Pigeon codec (handles type bytes 129 and 130) ────────────────────

@interface URLLauncherPigeonWriter : FlutterStandardWriter
@end

@implementation URLLauncherPigeonWriter
- (void)writeValue:(id)value {
    if ([value isKindOfClass:[URLLaunchResultWrapper class]]) {
        [self writeByte:129];
        [self writeValue:@(((URLLaunchResultWrapper *)value).value)];
    } else if ([value isKindOfClass:[URLInAppLoadResultWrapper class]]) {
        [self writeByte:130];
        [self writeValue:@(((URLInAppLoadResultWrapper *)value).value)];
    } else {
        [super writeValue:value];
    }
}
@end

@interface URLLauncherPigeonReader : FlutterStandardReader
@end

@implementation URLLauncherPigeonReader
- (id)readValueOfType:(UInt8)type {
    if (type == 129) {
        NSNumber *raw = [self readValue];
        return [URLLaunchResultWrapper wrap:(URLLaunchResult)[raw integerValue]];
    } else if (type == 130) {
        NSNumber *raw = [self readValue];
        return [URLInAppLoadResultWrapper wrap:(URLInAppLoadResult)[raw integerValue]];
    }
    return [super readValueOfType:type];
}
@end

@interface URLLauncherPigeonReaderWriter : FlutterStandardReaderWriter
@end

@implementation URLLauncherPigeonReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
    return [[URLLauncherPigeonWriter alloc] initWithData:data];
}
- (FlutterStandardReader *)readerWithData:(NSData *)data {
    return [[URLLauncherPigeonReader alloc] initWithData:data];
}
@end

@interface URLLauncherPigeonCodec : FlutterStandardMessageCodec
+ (instancetype)sharedInstance;
@end

@implementation URLLauncherPigeonCodec
+ (instancetype)sharedInstance {
    static URLLauncherPigeonCodec *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        URLLauncherPigeonReaderWriter *rw = [[URLLauncherPigeonReaderWriter alloc] init];
        instance = (URLLauncherPigeonCodec *)[URLLauncherPigeonCodec codecWithReaderWriter:rw];
    });
    return instance;
}
@end

// ─── Main plugin ─────────────────────────────────────────────────────────────

@interface URLLauncherPlugin ()
@end

@implementation URLLauncherPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    URLLauncherPlugin *instance = [[URLLauncherPlugin alloc] init];
    URLLauncherPigeonCodec *codec = [URLLauncherPigeonCodec sharedInstance];
    NSObject<FlutterBinaryMessenger> *messenger = [registrar messenger];

    // ── canLaunchUrl ──────────────────────────────────────────────────────────
    FlutterBasicMessageChannel *canLaunchChannel = [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.url_launcher_ios.UrlLauncherApi.canLaunchUrl"
               binaryMessenger:messenger
                         codec:codec];
    [canLaunchChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *urlString = args[0];
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) {
            reply(@[[URLLaunchResultWrapper wrap:URLLaunchResultInvalidUrl]]);
            return;
        }
        BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];
        reply(@[[URLLaunchResultWrapper wrap:canOpen ? URLLaunchResultSuccess : URLLaunchResultFailure]]);
    }];

    // ── launchUrl ─────────────────────────────────────────────────────────────
    FlutterBasicMessageChannel *launchChannel = [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.url_launcher_ios.UrlLauncherApi.launchUrl"
               binaryMessenger:messenger
                         codec:codec];
    [launchChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *urlString = args[0];
        BOOL universalLinksOnly = [args[1] boolValue];
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url) {
            reply(@[[URLLaunchResultWrapper wrap:URLLaunchResultInvalidUrl]]);
            return;
        }
        NSDictionary *options = universalLinksOnly
            ? @{UIApplicationOpenURLOptionUniversalLinksOnly: @YES}
            : @{};
        [[UIApplication sharedApplication] openURL:url options:options completionHandler:^(BOOL success) {
            reply(@[[URLLaunchResultWrapper wrap:success ? URLLaunchResultSuccess : URLLaunchResultFailure]]);
        }];
    }];

    // ── openUrlInSafariViewController ─────────────────────────────────────────
    FlutterBasicMessageChannel *safariChannel = [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.url_launcher_ios.UrlLauncherApi.openUrlInSafariViewController"
               binaryMessenger:messenger
                         codec:codec];
    [safariChannel setMessageHandler:^(id message, FlutterReply reply) {
        NSArray *args = (NSArray *)message;
        NSString *urlString = (args.count > 0) ? args[0] : nil;
        NSURL *url = urlString ? [NSURL URLWithString:urlString] : nil;
        if (!url) {
            reply(@[[URLInAppLoadResultWrapper wrap:URLInAppLoadResultInvalidUrl]]);
            return;
        }
        // Reply immediately so launchUrl returns — OAuth callback arrives via app_links.
        // Use external Safari (openURL) instead of SFSafariViewController to avoid
        // view hierarchy complexity and completion-block issues on iOS 26.
        reply(@[[URLInAppLoadResultWrapper wrap:URLInAppLoadResultSuccess]]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        });
    }];

    // ── closeSafariViewController ─────────────────────────────────────────────
    FlutterBasicMessageChannel *closeChannel = [FlutterBasicMessageChannel
        messageChannelWithName:@"dev.flutter.pigeon.url_launcher_ios.UrlLauncherApi.closeSafariViewController"
               binaryMessenger:messenger
                         codec:codec];
    [closeChannel setMessageHandler:^(id message, FlutterReply reply) {
        // No-op: we use openURL (external Safari), nothing to close programmatically.
        reply(@[[NSNull null]]);
    }];
}

@end
