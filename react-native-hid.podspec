# react-native-hid.podspec
require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'react-native-hid'
  s.version      = package['version']
  s.summary      = 'Cross-platform HID for React Native (macOS/Windows)'
  s.license      = { :type => 'MIT' }
  s.authors      = { 'You' => 'you@example.com' }
  s.homepage     = 'https://github.com/rmtry/react-native-hid.git'
  s.source       = { :git => 'https://github.com/rmtry/react-native-hid.git', :tag => s.version }

  s.platforms    = { :osx => '10.14' }      # <-- macOS target
  s.source_files = [
    'macos/**/*.{h,m,mm}',
    'cpp/src/**/*.{h,hh,hpp,c,cc,cpp,mm}',
    'third_party/hidapi/mac/hid.c'
  ]
  s.header_mappings_dir = 'cpp/include'

  # C++17 and header search paths for the core/hidapi
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'gnu++17',
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/cpp/include" "$(PODS_TARGET_SRCROOT)/third_party/hidapi"'
  }

  # Link the Apple frameworks hidapi/mac needs
  s.frameworks = 'IOKit', 'CoreFoundation'

  # React Native (macOS) pods are resolved by the app; you generally
  # don’t need to declare them here for autolinking to work.
end
