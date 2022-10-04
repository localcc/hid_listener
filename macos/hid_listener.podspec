#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint hid_listener.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'hid_listener'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*', '../shared/**.{c,h}'
  s.preserve_paths = '../shared/module/module.modulemap'

  s.xcconfig = { 
    'HEADER_SEARCH_PATHS' => __dir__ + '/../shared'
  }

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'SWIFT_INCLUDE_PATHS' => __dir__ + '/../shared/**' }
  s.swift_version = '5.0'
end
