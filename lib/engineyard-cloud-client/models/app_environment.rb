require 'engineyard-cloud-client/models'
require 'engineyard-cloud-client/errors'

module EY
  class CloudClient
    class AppEnvironment < ApiStruct.new(:id, :app, :environment, :uri, :domain_name, :migrate_command, :migrate)

      # Return a constrained list of app_environments given a set of constraints like:
      #
      # * app_name
      # * account_name
      # * environment_name
      # * remotes:  An array of git remote URIs
      #
      def self.resolve(api, constraints)
        clean_constraints = constraints.reject { |k,v| v.nil? }
        params = {'constraints' => clean_constraints}
        response = api.request("/app_environments/resolve", :method => :get, :params => params)['resolver']
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
        [account_name, app_name, environment_name].join('/')
      end

      def last_deployment
        Deployment.last(api, self)
      end

      def new_deployment(attrs)
        Deployment.from_hash(api, attrs.merge(:app_environment => self))
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
