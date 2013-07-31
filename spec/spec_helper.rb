if self.class.const_defined?(:EY_ROOT)
  raise "don't require the spec helper twice!"
end

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

EY_ROOT = File.expand_path("../..", __FILE__)
require 'rubygems'
require 'bundler/setup'

# Bundled gems
require 'fakeweb'
require 'fakeweb_matcher'

require 'multi_json'

# Engineyard gem
$LOAD_PATH.unshift(File.join(EY_ROOT, "lib"))
require 'engineyard-cloud-client'
require 'engineyard-cloud-client/test'

# Spec stuff
require 'rspec'
require 'tmpdir'
require 'yaml'
require 'pp'
require 'pry'
support = Dir[File.join(EY_ROOT,'/spec/support/*.rb')]
support.each{|helper| require helper }

#support = Dir[File.join(EY_ROOT,'/spec/support/fake_awsm/*.rb')]
#support.each{|helper| require helper }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.include SpecHelpers

  config.before(:all) do
    FakeWeb.allow_net_connect = false
  end

end
