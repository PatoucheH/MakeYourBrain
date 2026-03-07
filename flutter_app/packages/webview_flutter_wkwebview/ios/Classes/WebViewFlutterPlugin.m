// iOS 26 workaround: pure Objective-C stub for webview_flutter_wkwebview.
// The Swift-based plugin crashes on iOS 26 in swift_getObjectType during
// plugin registration. This stub registers a no-op platform view factory.
// Web views (used by google_mobile_ads for ads) will not render, but the
// app itself will launch successfully.

#import "WebViewFlutterPlugin.h"
#import <UIKit/UIKit.h>

// ─── Stub platform view (empty UIView) ───────────────────────────────────────

@interface StubWebView : NSObject <FlutterPlatformView>
@property (nonatomic, strong) UIView *view;
@end

@implementation StubWebView
- (instancetype)init {
    self = [super init];
    if (self) {
        _view = [[UIView alloc] init];
        _view.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (UIView *)view {
    return _view;
}
@end

// ─── Stub view factory ────────────────────────────────────────────────────────

@interface StubWebViewFactory : NSObject <FlutterPlatformViewFactory>
@end

@implementation StubWebViewFactory
- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id)args {
    return [[StubWebView alloc] init];
}
- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}
@end

// ─── Main plugin ──────────────────────────────────────────────────────────────

@implementation WebViewFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    StubWebViewFactory *factory = [[StubWebViewFactory alloc] init];
    [registrar registerViewFactory:factory withId:@"plugins.flutter.io/webview"];
}

@end
