#
# Be sure to run `pod lib lint NEListenTogetherKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NEListenTogetherKit'
  s.version          = '1.0.0'
  s.summary          = 'A short description of NEListenTogetherKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/gingerjin1993@gmail.com/NEListenTogetherKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mayajie@gmail.com' => 'mayajie@corp.netease.com' }
  s.source           = { :git => 'https://github.com/mayajie@corp.netease.com/NEListenTogetherKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'

  s.source_files = 'NEListenTogetherKit/Classes/**/*'
  
  # s.resource_bundles = {
  #   'NEListenTogetherKit' => ['NEListenTogetherKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'NERoomKit/Base_Special'
  s.dependency 'NERoomKit/Beauty_Special'
  s.dependency 'NERoomKit/Segment_Special'
  s.dependency 'NERoomKit/Audio_Special'
  s.dependency 'NECopyrightedMedia'

end
