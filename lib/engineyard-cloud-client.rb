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

    def update_vars(app_environment)
      response = self.put("/app_environments/#{app_environment.id}", {:vars => app_environment.vars})
      app_environment.vars = response["vars"]
      app_environment
    end

    def addons_for(account)
      self.get("/accounts/#{account.id}/addons")
    end

    # TODO: unhaxor
    # This should load an api endpoint that deals directly in app_deployments
    def app_environments
      @app_environments ||= apps.map { |app| app.app_environments }.flatten
    end

    def current_user
      EY::CloudClient::User.from_hash(self, get('/current_user')['user'])
    end

    # Accepts an environment name and optional account name and returns the
    # best matching environment for the given constraints.
    #
    # This is a shortcut for Environment.resolve
    # Raises if nothing is found or if more than one env is found.
    def environment_by_name(environment_name, account_name=nil)
      EY::CloudClient::Environment.by_name(self, environment_name, account_name)
    end

    # For ease of use:
    alias :env_by_name :environment_by_name

  end # API
end # EY
