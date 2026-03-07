Pod::Spec.new do |s|
  s.name             = 'app_links'
  s.version          = '6.4.1'
  s.summary          = 'iOS app_links - pure ObjC patch for iOS 26.'
  s.description      = 'Pure Objective-C reimplementation to avoid swift_getObjectType crash on iOS 26.'
  s.homepage         = 'https://github.com/llfbandit/app_links'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.ios.deployment_target = '12.0'
  s.dependency 'Flutter'
end
