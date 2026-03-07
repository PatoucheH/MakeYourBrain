// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import Foundation

/// Legacy method-channel-based implementation of shared_preferences for iOS.
/// Uses NSUserDefaults directly via FlutterMethodChannel.
public class LegacySharedPreferencesPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "plugins.flutter.io/shared_preferences_foundation",
      binaryMessenger: registrar.messenger())
    let instance = LegacySharedPreferencesPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let defaults = UserDefaults.standard
    switch call.method {
    case "getAll":
      let args = call.arguments as? [String: Any]
      let prefix = args?["prefix"] as? String ?? "flutter."
      let allowList = args?["allowList"] as? [String]
      result(getAllPrefs(prefix: prefix, allowList: allowList))
    case "setBool":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? Bool else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for setBool", details: nil))
        return
      }
      defaults.set(value, forKey: key)
      result(true)
    case "setInt":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for setInt", details: nil))
        return
      }
      defaults.set(value, forKey: key)
      result(true)
    case "setDouble":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? Double else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for setDouble", details: nil))
        return
      }
      defaults.set(value, forKey: key)
      result(true)
    case "setString":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for setString", details: nil))
        return
      }
      defaults.set(value, forKey: key)
      result(true)
    case "setStringList":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? [String] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for setStringList", details: nil))
        return
      }
      defaults.set(value, forKey: key)
      result(true)
    case "remove":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for remove", details: nil))
        return
      }
      defaults.removeObject(forKey: key)
      result(true)
    case "clear":
      let args = call.arguments as? [String: Any]
      let prefix = args?["prefix"] as? String ?? "flutter."
      let allowList = args?["allowList"] as? [String]
      clearPrefs(prefix: prefix, allowList: allowList)
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getAllPrefs(prefix: String, allowList: [String]?) -> [String: Any] {
    var filtered: [String: Any] = [:]
    for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
      guard key.hasPrefix(prefix) else { continue }
      if let allowList = allowList {
        if allowList.contains(key) { filtered[key] = value }
      } else {
        filtered[key] = value
      }
    }
    return filtered
  }

  private func clearPrefs(prefix: String, allowList: [String]?) {
    let defaults = UserDefaults.standard
    for (key, _) in defaults.dictionaryRepresentation() {
      guard key.hasPrefix(prefix) else { continue }
      if let allowList = allowList {
        if !allowList.contains(key) { defaults.removeObject(forKey: key) }
      } else {
        defaults.removeObject(forKey: key)
      }
    }
  }
}
