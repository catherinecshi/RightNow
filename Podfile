platform :ios, '18.0'

target 'RightNow' do
  use_frameworks!

  # Pods for RightNow
	# reactive
    	pod 'RxSwift'
    	pod 'RxCocoa'
	pod 'RxDataSources'

	#swift lint
	pod 'SwiftLint'

	# firebase
	pod 'Firebase/Core'
	pod 'Firebase/Firestore'
	pod 'Firebase/Auth'
	pod 'Firebase/Storage'
	pod 'Firebase/Analytics'
	pod 'Firebase/Crashlytics'

	# google
	pod 'GoogleSignIn'
end

target 'RightNowTests' do
  use_frameworks!

  # Pods for RightNow
	# reactive
    	pod 'RxSwift'
    	pod 'RxCocoa'
	pod 'RxDataSources'

	#swift lint
	pod 'SwiftLint'

	# firebase
	pod 'Firebase/Core'
	pod 'Firebase/Firestore'
	pod 'Firebase/Auth'
	pod 'Firebase/Storage'
	pod 'Firebase/Analytics'
	pod 'Firebase/Crashlytics'

	# google
	pod 'GoogleSignIn'
end

# Fix module conflicts
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Fix module conflicts
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      
      # Set consistent iOS version
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      
      # Explicitly enable module stability
      config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
      config.build_settings['DEFINES_MODULE'] = 'YES'
      
      # Fix Xcode 15+ issues
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end