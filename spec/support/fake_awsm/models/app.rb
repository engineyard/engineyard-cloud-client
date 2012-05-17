require 'gitable'
require 'dm-core'

class App
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :repository_uri, String
  property :app_type_id, String

  belongs_to :account
  has n, :app_environments
  has n, :environments, :through => :app_environments

  def gitable_uri
    Gitable::URI.parse(repository_uri)
  end

  def inspect
    "#<App name:#{name} account:#{account.name}>"
  end

end
