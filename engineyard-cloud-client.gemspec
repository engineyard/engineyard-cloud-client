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

  s.rubygems_version = %q{1.3.6}
  s.test_files = Dir.glob("spec/**/*")

  s.add_dependency('rest-client', '~>1.6.1')
  s.add_dependency('multi_json', '~>1.6')
  s.add_dependency('mime-types', '~>1.16') # The 2.0 version of mime-types doesn't work on 1.8.7

  s.add_development_dependency('rspec', '~>2.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('fakeweb')
  s.add_development_dependency('fakeweb-matcher')
  s.add_development_dependency('sinatra')
  s.add_development_dependency('realweb', '~>1.0.1')
  s.add_development_dependency('dm-core', '~>1.2.0')
  s.add_development_dependency('dm-migrations')
  s.add_development_dependency('dm-aggregates')
  s.add_development_dependency('dm-timestamps')
  s.add_development_dependency('dm-sqlite-adapter')
  s.add_development_dependency('ey_resolver', '~>0.2.1')
  s.add_development_dependency('rabl', '~>0.8.0')
  s.add_development_dependency('activesupport', '< 4.0.0')
  s.add_development_dependency('oj')
  s.add_development_dependency('pry')
end
