Pod::Spec.new do |s|
  s.name             = 'shared_preferences_foundation'
  s.version          = '2.5.6'
  s.summary          = 'iOS shared_preferences plugin patched for iOS 26.'
  s.description      = 'Stores data in NSUserDefaults. Patched to use legacy path to fix iOS 26 crash in UserDefaultsApiSetup.'
  s.homepage         = 'https://github.com/flutter/packages'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'
  s.ios.deployment_target = '12.0'
  s.dependency 'Flutter'
  s.swift_version    = '5.0'
end
