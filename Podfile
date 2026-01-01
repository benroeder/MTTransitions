workspace 'MTTransitionsDemo.xcworkspace'
use_frameworks!

# iOS Demo
target 'MTTransitionsDemo' do
  project 'MTTransitionsDemo.xcodeproj'
  platform :ios, '11.0'
  pod 'MTTransitions', :path => '.'
end

# macOS Demo
target 'MTTransitionsMacDemo' do
  project 'MTTransitionsMacDemo.xcodeproj'
  platform :osx, '13.0'
  pod 'MTTransitions', :path => '.'
end

# tvOS Demo
target 'MTTransitionsTVDemo' do
  project 'MTTransitionsTVDemo.xcodeproj'
  platform :tvos, '14.0'
  pod 'MTTransitions', :path => '.'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Remove duplicate -lc++ linker flags
      ldflags = config.build_settings['OTHER_LDFLAGS']
      if ldflags.is_a?(Array)
        config.build_settings['OTHER_LDFLAGS'] = ldflags.uniq
      end
      # Disable App Intents metadata extraction (not used)
      config.build_settings['APP_INTENTS_METADATA_EXTRACTOR_ENABLED'] = 'NO'
    end
  end
end
