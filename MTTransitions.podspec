Pod::Spec.new do |s|
  s.name         = 'MTTransitions'
  s.version      = '1.6.6'
  s.license = 'MIT'
  s.requires_arc = true
  s.source = { :git => 'https://github.com/alexiscn/MTTransitions.git', :tag => s.version.to_s }

  s.summary         = 'MTTransitions'
  s.homepage        = 'https://github.com/alexiscn/MTTransitions'
  s.license         = { :type => 'MIT' }
  s.author          = { 'alexiscn' => 'shuifengxu@gmail.com' }
  s.swift_version   = '5.0'
  s.source_files    = 'Source/**/*.{swift,metal,h}'
  s.resource  = 'Source/**/Assets.bundle'
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '13.0'
  s.xcconfig = { 'MTL_HEADER_SEARCH_PATHS' => '${PODS_CONFIGURATION_BUILD_DIR}/MetalPetal/MetalPetal.framework/Headers ${PODS_CONFIGURATION_BUILD_DIR}/MetalPetal-macOS/MetalPetal.framework/Headers ${PODS_CONFIGURATION_BUILD_DIR}/MetalPetal-iOS/MetalPetal.framework/Headers ${PODS_CONFIGURATION_BUILD_DIR}/MetalPetal-tvOS/MetalPetal.framework/Headers'}
  s.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -Xfrontend -suppress-warnings' }
  
  s.weak_frameworks = 'MetalKit'
  
  s.dependency 'MetalPetal'
  s.dependency 'MetalPetal/Swift'
  
end
