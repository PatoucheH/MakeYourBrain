// iOS 26 stub: prevents swift_getObjectType crash during plugin registration.
// WebView functionality (used by google_mobile_ads) will not render properly
// on iOS 26 until the upstream plugin is fixed. The app itself will launch.

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Stub iOS implementation of [WebViewPlatform].
///
/// This stub prevents the app from crashing at startup on iOS 26.
/// Web views (e.g. ads) will not render on iOS 26 until the upstream
/// webview_flutter_wkwebview plugin is updated.
class WebKitWebViewPlatform extends WebViewPlatform {
  /// Registers this class as the default instance of [WebViewPlatform].
  static void registerWith() {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }
}
