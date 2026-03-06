import Flutter
import UIKit
import UserNotifications
import app_links
import url_launcher_ios
import webview_flutter_wkwebview

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    // Register plugins manually — shared_preferences_foundation is intentionally skipped
    // because it crashes on iOS 26 (swift_getObjectType null pointer in registerWithRegistrar).
    // If you add a new Flutter plugin, also add its registrar call here.
    // Source of truth: ios/Runner/GeneratedPluginRegistrant.m (auto-generated).
    AppLinksIosPlugin.register(with: self.registrar(forPlugin: "AppLinksIosPlugin")!)
    FLTFirebaseCorePlugin.register(with: self.registrar(forPlugin: "FLTFirebaseCorePlugin")!)
    FLTFirebaseMessagingPlugin.register(with: self.registrar(forPlugin: "FLTFirebaseMessagingPlugin")!)
    FLTGoogleMobileAdsPlugin.register(with: self.registrar(forPlugin: "FLTGoogleMobileAdsPlugin")!)
    FLTGoogleSignInPlugin.register(with: self.registrar(forPlugin: "FLTGoogleSignInPlugin")!)
    // SharedPreferencesPlugin — SKIPPED (iOS 26 crash)
    SignInWithApplePlugin.register(with: self.registrar(forPlugin: "SignInWithApplePlugin")!)
    URLLauncherPlugin.register(with: self.registrar(forPlugin: "URLLauncherPlugin")!)
    WebViewFlutterPlugin.register(with: self.registrar(forPlugin: "WebViewFlutterPlugin")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
