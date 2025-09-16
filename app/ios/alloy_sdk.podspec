Pod::Spec.new do |s|
  s.name             = 'alloy_sdk'
  s.version          = '0.1.0'
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

  # Privacy manifest for required reason APIs usage
  # See https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  s.resource_bundles = {'alloy_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
