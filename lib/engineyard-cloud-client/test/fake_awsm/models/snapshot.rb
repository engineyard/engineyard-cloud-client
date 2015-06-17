require 'dm-core'

class Snapshot
  include DataMapper::Resource

  property :id, Serial
  property :amazon_id, String
  property :name, String
  property :size, Integer
  property :arch, Integer
  property :role, String
  
  belongs_to :environment

end
