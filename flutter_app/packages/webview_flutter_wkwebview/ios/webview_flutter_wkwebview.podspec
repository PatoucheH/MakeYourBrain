Pod::Spec.new do |s|
  s.name             = 'webview_flutter_wkwebview'
  s.version          = '3.23.8'
  s.summary          = 'iOS webview_flutter_wkwebview - pure ObjC stub for iOS 26.'
  s.description      = 'Pure Objective-C stub to avoid swift_getObjectType crash on iOS 26.'
  s.homepage         = 'https://github.com/flutter/packages'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.ios.deployment_target = '12.0'
  s.dependency 'Flutter'
end
