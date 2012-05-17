require 'dm-core'

class AppEnvironment
  include DataMapper::Resource

  property :id, Serial
  property :app_id, Integer
  property :environment_id, Integer

  belongs_to :app
  belongs_to :environment

  def inspect
    "#<AppEnvironment app:#{app.name} env:#{environment.name}>"
  end

end
