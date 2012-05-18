require 'dm-core'

class Deployment
  include DataMapper::Resource

  property :id, Serial
  property :app_environment_id, Integer

  belongs_to :app_environment

  def inspect
    "#<Deployment app_environment:#{app_environment.inspect}>"
  end

end
