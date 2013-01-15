require 'dm-core'

class Deployment
  include DataMapper::Resource

  AWSM_SERVERSIDE_VERSION = '2.0.0.awsm'

  property :id,                 Serial
  property :created_at,         DateTime
  property :finished_at,        DateTime
  property :commit,             String, :default => 'abcdef1234'*4
  property :migrate,            String
  property :migrate_command,    String
  property :ref,                String
  property :successful,         Boolean
  property :output,             Text
  property :serverside_version, String

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

  # pretend to trigger a deploy
  #
  # this deploy will be instant, unlike real deploys
  #
  def deploy
    unless serverside_version
      # only set serverside version if it's not set, to imitate the api
      # behavior of choosing its own serverside version if one is not
      # sent
      update :serverside_version => AWSM_SERVERSIDE_VERSION
    end
    finished!(
      :successful => true,
      :output => 'Deployment triggered by the API'
    )
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
