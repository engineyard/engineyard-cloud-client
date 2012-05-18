require 'dm-core'

class Instance
  include DataMapper::Resource

  property :id,              Serial
  property :name,            String
  property :role,            String
  property :status,          String
  property :amazon_id,       String
  property :public_hostname, String

  belongs_to :environment

  def inspect
    "#<Instance environment:#{environment.name} role:#{role} name:#{name}>"
  end

  def bridge
    %w[app_master solo].include?(role)
  end

end
