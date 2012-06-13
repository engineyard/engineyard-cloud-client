module EY
  class CloudClient
  end
end

require 'engineyard-cloud-client/connection'
require 'engineyard-cloud-client/model_registry'
require 'engineyard-cloud-client/models'
require 'engineyard-cloud-client/rest_client_ext'
require 'engineyard-cloud-client/resolver_result'
require 'engineyard-cloud-client/version'
require 'engineyard-cloud-client/errors'
require 'multi_json'
require 'pp'
require 'forwardable'

module EY
  class CloudClient
    extend Forwardable

    def_delegators :connection, :head, :get, :post, :put, :delete, :request, :endpoint, :token

    attr_reader :connection

    # Initialize a new EY::CloudClient.
    #
    # Creates and stores a new Connection for communicating with EY Cloud.
    #
    # See EY::CloudClient::Connection for options.
    def initialize(options={})
      @connection = Connection.new(options)
    end

    def authenticate!(*a)
      connection.authenticate!(*a)
    end

    def authenticated?
      connection.authenticated?
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

  end # API
end # EY
