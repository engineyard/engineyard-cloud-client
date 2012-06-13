require 'engineyard-cloud-client/models'
require 'engineyard-cloud-client/models/recipes'
require 'engineyard-cloud-client/errors'

module EY
  class CloudClient
    class Environment < ApiStruct.new(:id, :name, :framework_env,
                                      :instances_count,
                                      :instance_status,
                                      :username, :app_server_stack_name,
                                      :load_balancer_ip_address
                                     )

      # Return list of all Environments linked to all current user's accounts
      def self.all(api)
        self.from_array(api, api.get("/environments", "no_instances" => "true")["environments"])
      end

      # Return a constrained list of environments given a set of constraints like:
      #
      # * app_name:  app name full or partial match string
      # * account_name:  account name full or partial match string
      # * environment_name:  environment name full or partial match string
      # * remotes:  An array of git remote URIs
      #
      def self.resolve(api, constraints)
        clean_constraints = constraints.reject { |k,v| v.nil? }
        params = {'constraints' => clean_constraints}
        response = api.get("/environments/resolve", params)['resolver']
        matches = from_array(api, response['matches'])
        ResolverResult.new(api, matches, response['errors'], response['suggestions'])
      end

      # Usage
      # Environment.create(api, {
      #      app: app,                            # requires: app.id
      #      name: 'myapp_production',
      #      region: 'us-west-1',                 # default: us-east-1
      #      app_server_stack_name: 'nginx_thin', # default: nginx_passenger3
      #      framework_env: 'staging'             # default: production
      #      cluster_configuration: {
      #        configuration: 'single'            # default: single, cluster, custom
      #      }
      # })
      #
      # NOTE: Syntax above is for Ruby 1.9. In Ruby 1.8, keys must all be strings.
      #
      # TODO - allow any attribute to be sent through that the API might allow; e.g. region, ruby_version, stack_label
      def self.create(api, attrs={})
        app    = attrs.delete("app")
        cluster_configuration = attrs.delete('cluster_configuration')
        raise EY::CloudClient::AttributeRequiredError.new("app", EY::CloudClient::App) unless app
        raise EY::CloudClient::AttributeRequiredError.new("name") unless attrs["name"]

        params = {"environment" => attrs.dup}
        unpack_cluster_configuration(params, cluster_configuration)
        response = api.post("/apps/#{app.id}/environments", params)
        self.from_hash(api, response['environment'])
      end
      attr_accessor :apps, :account

      def attributes=(attrs)
        account_attrs    = attrs.delete('account')
        apps_attrs       = attrs.delete('apps')
        instances_attrs  = attrs.delete('instances')

        super

        set_account   account_attrs   if account_attrs
        set_apps      apps_attrs      if apps_attrs
        set_instances instances_attrs if instances_attrs
      end

      def add_app_environment(app_env)
        @app_environments ||= []
        existing_app_env = @app_environments.detect { |ae| app_env.environment == ae.environment }
        unless existing_app_env
          @app_environments << app_env
        end
        existing_app_env || app_env
      end

      def app_environments
        @app_environments ||= []
      end

      def apps
        app_environments.map { |app_env| app_env.app }
      end

      def instances
        @instances ||= request_instances
      end

      def account_name
        account && account.name
      end

      def ssh_username=(user)
        self.username = user
      end

      def logs
        Log.from_array(api, api.get("/environments/#{id}/logs")["logs"])
      end

      def deploy_to_instances
        instances.select { |inst| inst.has_app_code? }
      end

      def bridge
        @bridge ||= instances.detect { |inst| inst.bridge? }
      end

      def bridge!(ignore_bad_bridge = false)
        if bridge.nil?
          raise NoBridgeError.new(name)
        elsif !ignore_bad_bridge && bridge.status != "running"
          raise BadBridgeStatusError.new(bridge.status, api.endpoint)
        end
        bridge
      end

      def update
        api.put("/environments/#{id}/update_instances")
        true # raises on failure
      end
      alias rebuild update

      def recipes
        Recipes.new(api, self)
      end

      # See Recipes#run
      def run_custom_recipes
        recipes.run
      end

      # See Recipes#download
      def download_recipes
        recipes.download
      end

      # See Recipes#upload_path
      def upload_recipes_at_path(recipes_path)
        recipes.upload_path(recipes_path)
      end

      # See Recipes#upload
      def upload_recipes(file_to_upload)
        recipes.upload(file_to_upload)
      end

      def shorten_name_for(app)
        name.gsub(/^#{Regexp.quote(app.name)}_/, '')
      end

      protected

      def set_account(account_attrs)
        @account = Account.from_hash(api, account_attrs)
        @account.add_environment(self)
        @account
      end

      # Creating an AppEnvironment will come back and call add_app_environment
      # (above) to associate this model with the AppEnvironment. (that's why we
      # don't save anything here.)
      def set_apps(apps_attrs)
        (apps_attrs || []).each do |app|
          AppEnvironment.from_hash(api, {'app' => app, 'environment' => self})
        end
      end

      def set_instances(instances_attrs)
        @instances = load_instances(instances_attrs)
      end

      def request_instances
        if instances_count.zero?
          []
        else
          instances_attrs = api.get("/environments/#{id}/instances")["instances"]
          load_instances(instances_attrs)
        end
      end

      def load_instances(instances_attrs)
        Instance.from_array(api, instances_attrs, 'environment' => self)
      end

      # attrs["cluster_configuration"]["cluster"] can be 'single', 'cluster', or 'custom'
      # attrs["cluster_configuration"]["ip"] can be
      #   * 'host' (amazon public hostname)
      #   * 'new' (Elastic IP assigned, default)
      #   * or an IP id
      # if 'custom' cluster, then...
      def self.unpack_cluster_configuration(attrs, configuration)
        if configuration
          attrs["cluster_configuration"] = configuration
          attrs["cluster_configuration"]["configuration"] ||= 'single'
          attrs["cluster_configuration"]["ip_id"] = configuration.delete("ip") || 'new' # amazon public hostname; alternate is 'new' for Elastic IP

          # if cluster_type == 'custom'
          #   attrs['cluster_configuration'][app_server_count] = options[:app_instances] || 2
          #   attrs['cluster_configuration'][db_slave_count]   = options[:db_instances] || 0
          #   attrs['cluster_configuration'][instance_size]    = options[:app_size] if options[:app_size]
          #   attrs['cluster_configuration'][db_instance_size] = options[:db_size] if options[:db_size]
          # end
          # at
        end
      end
    end
  end
end
