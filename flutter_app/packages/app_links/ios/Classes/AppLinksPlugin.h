#import <Flutter/Flutter.h>

@interface AppLinksIosPlugin : NSObject <FlutterPlugin, FlutterStreamHandler>

/// Called from AppDelegate to handle custom URL scheme links.
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

/// Called from AppDelegate to handle universal links.
- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *))restorationHandler;

@end
