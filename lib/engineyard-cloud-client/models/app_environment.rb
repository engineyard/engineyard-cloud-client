require 'engineyard-cloud-client/models/api_struct'
require 'engineyard-cloud-client/models/app'
require 'engineyard-cloud-client/models/environment'
require 'engineyard-cloud-client/models/deployment'
require 'engineyard-cloud-client/resolver_result'

module EY
  class CloudClient
    class AppEnvironment < ApiStruct.new(:id, :app, :environment, :uri, :domain_name, :migrate_command, :migrate, :vars, :vars_resolved)

      # Return a constrained list of app_environments given a set of constraints like:
      #
      # * app_name:  app name full or partial match string
      # * account_name:  account name full or partial match string
      # * environment_name:  environment name full or partial match string
      # * remotes:  An array of git remote URIs
      #
      def self.resolve(api, constraints)
        clean_constraints = constraints.reject { |k,v| v.nil? }
        params = {'constraints' => clean_constraints}
        response = api.get("/app_environments/resolve", params)['resolver']
        matches = from_array(api, response['matches'])
        ResolverResult.new(api, matches, response['errors'], response['suggestions'])
      end

      def initialize(api, attrs)
        super

        raise ArgumentError, 'AppEnvironment created without app!'         unless app
        raise ArgumentError, 'AppEnvironment created without environment!' unless environment
      end

      def attributes=(attrs)
        app_attrs         = attrs.delete('app')
        environment_attrs = attrs.delete('environment')
        super
        set_app         app_attrs         if app_attrs
        set_environment environment_attrs if environment_attrs
      end

      def account
        app.account
      end

      def account_name
        app.account_name
      end

      def app_name
        app.name
      end

      def environment_name
        environment.name
      end

      def repository_uri
        app.repository_uri
      end

      def hierarchy_name
        [account_name, app_name, environment_name].join(' / ')
      end

      def last_deployment
        Deployment.last(api, self)
      end

      # Create a new, unsaved, Deployment record.
      #
      # Call start on the return object to indicate to EY Cloud that you
      # will be starting a deployment using your own connection to your
      # servers. This is the way that the engineyard gem does deployments.
      def new_deployment(attrs)
        Deployment.from_hash(api, attrs.merge(:app_environment => self))
      end

      # Trigger a deployment on the api side.
      #
      # This is like hitting the deploy button on the web interface.
      #
      # Returns a started deployment that will run from EY Cloud automatically.
      # Load the deployment again to see when it finishes. This action returns
      # immediately before the deployment is complete.
      def deploy(attrs)
        Deployment.deploy(api, self, attrs)
      end

      def sort_attributes
        [sort_string(account_name), sort_string(app_name), sort_string(environment_name)]
      end

      protected

      def set_app(app_or_hash)
        self.app = App.from_hash(api, app_or_hash)
        app.add_app_environment(self)
        app
      end

      def set_environment(env_or_hash)
        self.environment = Environment.from_hash(api, env_or_hash)
        environment.add_app_environment(self)
        environment
      end

    end
  end
end
