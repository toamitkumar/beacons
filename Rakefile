# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'beacon'
  app.identifier = "com.test.#{app.name}"
  app.version = '0.1'

  app.interface_orientations = [:landscape_left, :landscape_right]
  
  app.deployment_target               = "7.0"

  app.frameworks += %w(CoreBluetooth CoreLocation)

  app.device_family               = [ :iphone, :ipad]
  # app.device_family               = :ipad

  # app.testflight.sdk = 'vendor/TestFlight'
  # app.testflight.api_token = 'bdb85b6f5efe34854ae4b3576d71917e_MTU0MjQ3NjIwMTQtMDEtMDEgMDA6MzA6NDcuMTQyMzc5'
  # app.testflight.team_token = '69baa6923c20fb2eba820cf10d9f0393_MzE5MzAyMjAxNC0wMS0wMSAxMTo1NDo1OC43NDk3NDg'
  # app.testflight.app_token = '5700c7f1-5fc3-499a-893e-1556b581af26'

  app.provisioning_profile = "/Users/amitkumar/Downloads/iOS_Team_Provisioning_Profile_.mobileprovision"
  # app.codesign_certificate = ""
end
