Pod::Spec.new do |s|
  s.name             = 'ios-payment-links'
  s.version          = "1.5.1"
  s.summary          = 'Appcharge Checkout SDK'
  s.description      = <<-DESC
A lightweight static binary SDK for Appcharge Checkout, providing
seamless integration with Appcharge payment flows.
  DESC

  s.homepage         = 'https://github.com/Appcharge/ios-payment-links'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }

  s.author           = { 'Appcharge' => 'paymob-release@appcharge.com' }

  s.platform           = :ios, '13.0'
  s.swift_versions     = ['5.5', '5.9', '6.0', '6.1']
  s.cocoapods_version  = '>= 1.16.0'

  s.source             = {
    :git => 'https://github.com/Appcharge/ios-payment-links.git',
    :tag => s.version.to_s
  }

  s.vendored_frameworks = 'ACPaymentLinks.xcframework'
  s.static_framework = true
  
end

