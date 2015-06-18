require 'dm-core'

class Environment
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :ssh_username, String
  property :app_server_stack_name, String
  property :load_balancer_ip_address, String
  property :framework_env, String

  belongs_to :account
  has n, :app_environments
  has n, :apps, :through => :app_environments
  has n, :instances
  has n, :snapshots

  def inspect
    "#<Environment name:#{name} account:#{account.name}>"
  end

  def instances_count
    instances.size
  end
end
