// iOS 26 stub: prevents swift_getObjectType crash during plugin registration.
// WebView functionality (used by google_mobile_ads) will not render properly
// on iOS 26 until the upstream plugin is fixed. The app itself will launch.

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

export 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart'
    show
        PlatformWebViewControllerCreationParams,
        PlatformWebViewController,
        PlatformWebViewWidget,
        PlatformWebViewWidgetCreationParams,
        PlatformNavigationDelegateCreationParams,
        PlatformNavigationDelegate,
        PlatformWebViewCookieManagerCreationParams,
        PlatformWebViewCookieManager,
        WebViewPlatform;

// ─── Stub creation params ─────────────────────────────────────────────────────

/// Stub creation params for [WebKitWebViewController].
class WebKitWebViewControllerCreationParams
    extends PlatformWebViewControllerCreationParams {
  /// Creates stub params.
  const WebKitWebViewControllerCreationParams();
}

// ─── Stub WebViewController ───────────────────────────────────────────────────

/// Stub iOS implementation of [PlatformWebViewController].
///
/// Used by google_mobile_ads to get the WKWebView identifier.
/// Returns -1 since this is a stub (no real WKWebView on iOS 26).
class WebKitWebViewController extends PlatformWebViewController {
  /// Creates a stub controller.
  WebKitWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) : super.implementation(params);

  /// Always returns -1 in this stub; no real WKWebView exists.
  int get webViewIdentifier => -1;
}

// ─── Stub WebViewPlatform ─────────────────────────────────────────────────────

/// Stub iOS implementation of [WebViewPlatform].
///
/// Registers itself so the app launches without crashing on iOS 26.
class WebKitWebViewPlatform extends WebViewPlatform {
  /// Registers this class as the default instance of [WebViewPlatform].
  static void registerWith() {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return WebKitWebViewController(params);
  }
}
