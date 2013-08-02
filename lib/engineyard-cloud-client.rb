module EY
  class CloudClient
  end
end

require 'engineyard-cloud-client/connection'
require 'engineyard-cloud-client/model_registry'
require 'engineyard-cloud-client/models/app'
require 'engineyard-cloud-client/models/app_environment'
require 'engineyard-cloud-client/models/environment'
require 'engineyard-cloud-client/models/user'
require 'multi_json'
require 'pp'
require 'forwardable'

module EY
  class CloudClient
    extend Forwardable

    def_delegators :connection, :head, :get, :post, :put, :delete, :request, :endpoint, :token, :token=, :authenticate!, :authenticated?

    attr_reader :connection

    # Initialize a new EY::CloudClient.
    #
    # Creates and stores a new Connection for communicating with EY Cloud.
    #
    # See EY::CloudClient::Connection for options.
    def initialize(options={})
      @connection = Connection.new(options)
    end

    def ==(other)
      other.is_a?(self.class) && other.connection == connection
    end

    def registry
      @registry ||= ModelRegistry.new
    end

    def resolve_environments(constraints)
      EY::CloudClient::Environment.resolve(self, constraints)
    end

    def resolve_app_environments(constraints)
      EY::CloudClient::AppEnvironment.resolve(self, constraints)
    end

    def environments
      @environments ||= EY::CloudClient::Environment.all(self)
    end

    def apps
      @apps ||= EY::CloudClient::App.all(self)
    end

    # TODO: unhaxor
    # This should load an api endpoint that deals directly in app_deployments
    def app_environments
      @app_environments ||= apps.map { |app| app.app_environments }.flatten
    end

    def current_user
      EY::CloudClient::User.from_hash(self, get('/current_user')['user'])
    end

    #
    # Accepts a name parameter and returns the FIRST environment by name
    # to match that parameter.
    #
    # WARNING WARNING WARNING WARNING WARNING
    #
    # THIS MAY NOT BE THE ENVIRONMENT YOU WERE LOOKING FOR. This method
    # returns the FIRST object in an array to match. If you name your
    # environments projectname_envtype (e.g. 'todo_production') and have
    # -zero- duplication of environment names *across accounts*, this is
    # probably going to work just fine for you.
    #
    # BUT
    #
    # On the other hand, IF YOU NAME ENVIRONMENTS WITH THE SAME NAME,
    # even across different accounts, (e.g. two or more 'production'
    # environments), this may not return the one you want. Take extra
    # steps, such as examining the number and type of instances, the
    # git URI, and/or the account name, to see if this is the
    # right environment.
    #
    # Usage exapmle:
    #
    # api = EY::CloudClient.new(token: 'token')
    # env = api.environment_by_name("something_production")
    # => <EY::CloudClient::Environment ...>
    def environment_by_name(name)
      (environments.select { |x| x.name == name }).first
    end

    # For ease of use:
    alias :env_by_name :environment_by_name

  end # API
end # EY
