// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import Foundation

/// Entry point for the shared_preferences plugin on iOS.
/// iOS 26 workaround: routes to LegacySharedPreferencesPlugin to avoid
/// the UserDefaultsApiSetup crash (EXC_BAD_ACCESS in swift_getObjectType).
public class SharedPreferencesPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    LegacySharedPreferencesPlugin.register(with: registrar)
  }
}
