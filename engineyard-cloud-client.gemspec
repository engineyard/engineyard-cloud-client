# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'engineyard-cloud-client/version'

Gem::Specification.new do |s|
  s.name = "engineyard-cloud-client"
  s.version = EY::CloudClient::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = "EY Cloud Team"
  s.email = "cloud@engineyard.com"
  s.homepage = "http://github.com/engineyard/engineyard-cloud-client"
  s.summary = "EY Cloud API Client"
  s.description = "This gem connects to the EY Cloud API"
  s.license = 'MIT'

  s.files = Dir.glob("{lib}/**/*") + %w(LICENSE README.md ChangeLog.md)
  s.require_path = 'lib'

  s.test_files = Dir.glob("spec/**/*")

  s.required_ruby_version = '>= 2.1'

  s.add_dependency('rest-client', '~>2.0')
  s.add_dependency('multi_json', '~>1.6')

  s.add_development_dependency('rspec', '~>3.7.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('webmock')
  s.add_development_dependency('sinatra', '~>1.4.8')
  s.add_development_dependency('realweb', '~>1.0.1')
  s.add_development_dependency('ardm-core', '~> 1.2')
  s.add_development_dependency('ardm-migrations')
  s.add_development_dependency('ardm-aggregates')
  s.add_development_dependency('ardm-timestamps')
  s.add_development_dependency('ardm-sqlite-adapter')
  s.add_development_dependency('ey_resolver', '~>0.2.1')
  s.add_development_dependency('rabl')
  s.add_development_dependency('activesupport', '< 4.0.0')
  s.add_development_dependency('oj')
  s.add_development_dependency('pry')
end
