require 'dm-core'

class Deployment
  include DataMapper::Resource

  property :id,                 Serial
  property :created_at,         DateTime
  property :finished_at,        DateTime
  property :commit,             String, :default => 'abcdef1234'*4
  property :migrate,            String
  property :migrate_command,    String
  property :ref,                String
  property :successful,         Boolean
  property :output,             Text

  belongs_to :app_environment

  def inspect
    "#<Deployment app_environment:#{app_environment.inspect}>"
  end

  def user_name
    app_environment.app.account.user.name
  end

  # normally a property, but we don't have the code to find this so just pretend
  def resolved_ref
    "resolved-#{ref}"
  end

  def finished?
    finished_at != nil
  end

  def finished!(attrs)
    return true if finished?
    attrs = attrs.dup
    attrs['finished_at'] ||= Time.now
    update(attrs)
  end

end
