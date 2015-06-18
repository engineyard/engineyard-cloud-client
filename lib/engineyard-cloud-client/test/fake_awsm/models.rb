Dir[File.expand_path('../models/*.rb', __FILE__)].each do |model|
  require model
end

require 'dm-migrations'
require 'dm-aggregates'
require 'dm-timestamps'

DataMapper.setup(:default, "sqlite::memory:")
DataMapper.finalize
DataMapper.auto_migrate!
