Pod::Spec.new do |s|
  s.name             = 'url_launcher_ios'
  s.version          = '6.3.4'
  s.summary          = 'iOS url_launcher - pure ObjC patch for iOS 26.'
  s.description      = 'Pure Objective-C reimplementation to avoid swift_getObjectType crash on iOS 26.'
  s.homepage         = 'https://github.com/flutter/packages'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.ios.deployment_target = '12.0'
  s.dependency 'Flutter'
  s.frameworks = 'SafariServices'
end
