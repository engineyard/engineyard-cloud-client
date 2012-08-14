require 'dm-core'

class Keypair
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :public_key, String
  property :fingerprint, String, :default => "12:34:56:78:9a:bc:de:f0:12:34:56:78:9a:bc:de:f0"

  belongs_to :user

end
