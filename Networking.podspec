Pod::Spec.new do |s|
    s.name         = 'Networking'
    s.version      = '0.1.0'
    s.summary      = 'Networking layer implementation'
    s.homepage     = 'https://www.github.com/joeypatino/networking'
    s.description  = <<-DESC
    Networking is an iOS Networking layer implementation written in Swift.
    DESC
    s.license = { :type => 'MIT', :file => 'LICENSE.md' }

    s.author       = { 'joey patino' => 'joey.patino@protonmail.com' }
    s.source       = { :git => 'https://www.github.com/joeypatino/networking.git', :tag => s.version.to_s }

    s.source_files  = 'Networking/Classes/**/*.swift'
    s.dependency 'Disk'
    
    s.platform = :ios
    s.swift_version = '5.0'
    s.ios.deployment_target  = '12.1'
end
