platform :ios, '14.0'

target 'RightNow' do
  use_frameworks!

  # Pods for RightNow
	# camera stuff
	pod 'CameraManager', '~> 5.1'
	pod 'SDWebImage', :modular_headers => true

	# reactive
    	pod 'RxSwift', '6.6.0'
    	pod 'RxCocoa', '6.6.0'
	pod 'RxDataSources', '~> 5.0'

	#swift lint
	pod 'SwiftLint'

	# firebase
	# pod 'FirebaseFirestoreSwift'
	pod 'Firebase/Core'
	pod 'Firebase/Firestore'
	pod 'Firebase/Auth'
	pod 'Firebase/Storage'
	$FirebaseSDKVersion = '10.22.0'

	# google
	pod 'GoogleSignIn', '~> 7.0.0'
	# pod 'GTMAppAuth', '~> 2.0.0'
  	# pod 'GTMSessionFetcher/Core', '~> 3.1.0'
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