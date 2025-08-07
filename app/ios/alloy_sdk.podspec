Pod::Spec.new do |s|
  s.name             = 'alloy_sdk'
  s.version          = '0.0.4'
  s.summary          = 'Alloy SDK for Flutter - Analytics and user tracking platform'
  s.description      = <<-DESC
Alloy SDK for Flutter provides analytics, user tracking, consent management, and contextual data services.
Features include user identification, metadata collection, TCF consent handling, and comprehensive analytics tracking.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ringier AG' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'test_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
