#import <Flutter/Flutter.h>
#import <WebKit/WebKit.h>

/// External API stub for google_mobile_ads interop.
/// Returns nil since this is a stub implementation for iOS 26.
@interface FWFWebViewFlutterWKWebViewExternalAPI : NSObject

+ (WKWebView *)webViewForIdentifier:(int64_t)identifier
                 withPluginRegistry:(id<FlutterPluginRegistry>)registry;

@end

@interface WebViewFlutterPlugin : NSObject <FlutterPlugin>
@end
