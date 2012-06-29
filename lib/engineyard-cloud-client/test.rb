require 'engineyard-cloud-client'

module EY::CloudClient::Test
end

begin
  require 'dm-core'
  require 'dm-migrations'
  require 'dm-aggregates'
  require 'dm-sqlite-adapter'
  require 'ey_resolver'
  require 'rabl'
rescue LoadError
  raise LoadError, <<-ERROR
engineyard-cloud-client needs the following gems to run in test mode:

group 'engineyard-cloud-client-test' do
  gem 'dm-core'
  gem 'dm-migrations'
  gem 'dm-aggregates'
  gem 'dm-sqlite-adapter'
  gem 'ey_resolver', '~>0.2.1'
  gem 'rabl'
end

Please add the above to your Gemfile.
  ERROR
end

require 'engineyard-cloud-client/test/scenario'
