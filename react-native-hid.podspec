# react-native-hid.podspec
Pod::Spec.new do |s|
  s.name         = 'react-native-hid'
  s.version      = '0.1.0'
  s.summary      = 'Cross-platform HID for React Native'
  s.license      = { :type => 'MIT' }
  s.source       = { :path => '.' }
  s.authors      = { 'You' => 'you@example.com' }
  s.homepage     = 'https://github.com/rmtry/react-native-hid.git'
#   s.source       = { :git => 'https://github.com/rmtry/react-native-hid.git', :tag => s.version }

  # macOS support
  s.platforms = { :osx => '10.14' }  # or higher

  # Your sources
  s.source_files = [
    'macos/**/*.{h,m,mm}',
    'cpp/src/**/*.{h,hpp,hh,c,cc,cpp,mm}',
    'third-party/hidapi/hidapi.h',
    'third-party/hidapi/mac/*.c'
  ]
  
  s.public_header_files = [
    'cpp/include/**/*.{h,hpp,hh}',
    'third-party/hidapi/hidapi.h'
  ]
  s.header_mappings_dir = 'cpp/include'

  # React dependency so <React/RCTBridgeModule.h> resolves
  s.dependency 'React-Core'

  # C++ + includes for your core/hidapi
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'gnu++17',
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/cpp/include" "$(PODS_TARGET_SRCROOT)/third_party/hidapi"'
  }

  # macOS frameworks used by hidapi mac backend
  s.frameworks = 'IOKit', 'CoreFoundation'
end
