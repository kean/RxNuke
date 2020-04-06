Pod::Spec.new do |s|
    s.name             = 'RxNuke'
    s.version          = '0.11.0'
    s.summary          = 'RxSwift extensions for Nuke'

    s.homepage         = 'https://github.com/kean/RxNuke'
    s.license          = 'MIT'
    s.author           = 'Alexander Grebenyuk'
    s.source           = { :git => 'https://github.com/kean/RxNuke.git', :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/a_grebenyuk'
    
    s.ios.deployment_target = '10.0'
    s.watchos.deployment_target = '3.0'
    s.osx.deployment_target = '10.12'
    s.tvos.deployment_target = '10.0'

    s.module_name = "RxNuke"

    s.dependency 'Nuke', '~> 8.0'
    s.dependency 'RxSwift', '~> 5.1.0'

    s.source_files  = 'Source/**/*'
end
