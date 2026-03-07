// iOS 26 workaround: pure Objective-C implementation of app_links iOS plugin.
// The Swift-based plugin crashes on iOS 26 in swift_getObjectType during
// plugin registration. Pure ObjC avoids the Swift type metadata system entirely.

#import "AppLinksPlugin.h"
#import <UIKit/UIKit.h>

@interface AppLinksIosPlugin ()
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, copy) NSString *initialLink;
@property (nonatomic, assign) BOOL initialLinkSent;
@property (nonatomic, copy) NSString *latestLink;
@end

@implementation AppLinksIosPlugin

// ─── Singleton ────────────────────────────────────────────────────────────────

+ (instancetype)shared {
    static AppLinksIosPlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppLinksIosPlugin alloc] init];
    });
    return instance;
}

// ─── FlutterPlugin registration ───────────────────────────────────────────────

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    AppLinksIosPlugin *instance = [AppLinksIosPlugin shared];

    FlutterMethodChannel *methodChannel = [FlutterMethodChannel
        methodChannelWithName:@"com.llfbandit.app_links/messages"
              binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:methodChannel];

    FlutterEventChannel *eventChannel = [FlutterEventChannel
        eventChannelWithName:@"com.llfbandit.app_links/events"
             binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];

    [registrar addApplicationDelegate:instance];
}

// ─── FlutterPlugin method handler ─────────────────────────────────────────────

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"getInitialLink"]) {
        result(self.initialLink);
    } else if ([call.method isEqualToString:@"getLatestLink"]) {
        result(self.latestLink);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

// ─── FlutterStreamHandler ─────────────────────────────────────────────────────

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.eventSink = events;
    if (!self.initialLinkSent && self.initialLink != nil) {
        self.initialLinkSent = YES;
        events(self.initialLink);
    }
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

// ─── Link handling ────────────────────────────────────────────────────────────

- (void)handleLink:(NSURL *)url {
    NSString *link = url.absoluteString;
    self.latestLink = link;
    if (self.initialLink == nil) {
        self.initialLink = link;
    }
    if (self.eventSink != nil) {
        self.initialLinkSent = YES;
        self.eventSink(link);
    }
}

// ─── AppDelegate integration ──────────────────────────────────────────────────

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    [self handleLink:url];
    return NO;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *))restorationHandler {
    if (userActivity.webpageURL) {
        [self handleLink:userActivity.webpageURL];
    }
    return NO;
}

@end
