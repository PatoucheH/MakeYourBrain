Pod::Spec.new do |s|
  s.name             = 'shared_preferences_foundation'
  s.version          = '2.5.6'
  s.summary          = 'iOS shared_preferences - pure ObjC patch for iOS 26.'
  s.description      = 'Pure Objective-C reimplementation to avoid swift_getObjectType crash on iOS 26.'
  s.homepage         = 'https://github.com/flutter/packages'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.ios.deployment_target = '12.0'
  s.dependency 'Flutter'
end
