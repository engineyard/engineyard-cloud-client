require 'engineyard-cloud-client/models/api_struct'
require 'engineyard-cloud-client/models/account'
require 'engineyard-cloud-client/models/app'
require 'engineyard-cloud-client/models/app_environment'
require 'engineyard-cloud-client/models/instance'
require 'engineyard-cloud-client/models/log'
require 'engineyard-cloud-client/models/recipes'
require 'engineyard-cloud-client/resolver_result'
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

      # Accepts an api object, environment name and optional account name
      # and returns the best matching environment for the given constraints.
      #
      # This is a shortcut for resolve_environments.
      # Raises if nothing is found or if more than one environment is found.
      def self.by_name(api, environment_name, account_name=nil)
        constraints = {
          :environment_name => environment_name,
          :account_name     => account_name,
        }
        resolver = resolve(api, constraints)

        resolver.one_match { |match| return match  }

        resolver.no_matches do |errors, suggestions|
          message = nil
          if suggestions.any?
            message = "Suggestions found:\n"
            suggestions.sourt_by{|suggest| suggest['account_name']}.each do |suggest|
              message << "\t#{suggest['account_name']}/#{suggest['env_name']}\n"
            end
          end

          raise ResourceNotFound.new([errors,message].compact.join("\n").strip)
        end

        resolver.many_matches do |matches|
          message = "Multiple environments possible, please be more specific:\n"
          matches.sort_by {|env| env.account}.each do |env|
            message << "\t#{env.account.name}/#{env.name}\n"
          end
          raise MultipleMatchesError.new(message)
        end
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

      def hierarchy_name
        "#{account_name}/#{name}"
      end

      def ssh_username=(user)
        self.username = user
      end

      def logs
        Log.from_array(api, api.get("/environments/#{id}/logs")["logs"])
      end

      def provisioned_instances
        instances.select { |inst| inst.provisioned? }
      end

      def deploy_to_instances
        provisioned_instances.select { |inst| inst.has_app_code? }
      end

      def bridge
        @bridge ||= instances.detect { |inst| inst.bridge? }
      end

      def bridge!(ignore_bad_bridge = false)
        if bridge.nil?
          raise NoBridgeError.new(name)
        elsif !ignore_bad_bridge && !bridge.running?
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

      #
      # Throws a POST request at the API to /add_instances and adds one instance
      # to this environment.
      #
      # Usage example:
      #
      # api = EY::CloudClient.new(token: 'your token here')
      # env = api.environment_by_name('your_env_name')
      #
      # env.add_instance(role: "app")
      # env.add_instance(role: "util", name: "foo")
      #
      # Note that the role for an instance MUST be either "app" or "util".
      # No other value is acceptable. The "name" parameter can be anything,
      # but it only applies to utility instances.
      def add_instance(opts)
        unless %w[app util].include?(opts[:role].to_s)
          # Fail immediately because we don't have valid arguments.
          raise InvalidInstanceRole, "Instance role must be one of: app, util"
        end

        # We know opts[:role] is right, name can be passed straight to the API.
        # Return the response body for error output, logging, etc.
        return api.post("/environments/#{id}/add_instances", :request => {
          "role" => opts[:role],
          "name" => opts[:name]
        })
      end

      #
      # Gets an instance's Amazon ID by its "id" attribute as reported
      # by AWSM. When an instance is added via the API, the JSON that's
      # returned contains an "id" attribute for that instance. Developers
      # may save that ID so they can later discover an instance's Amazon ID.
      # This is because, when an instance object is first *created* (see
      # #add_instance above), its Amazon ID isn't yet known. The object is
      # created, and *then* later provisioned, so you can't get an Amazon
      # ID until after provisioning has taken place. This method allows you
      # to send an ID to it, and then returns the instance object that
      # corresponds to that ID, which will have an Amazon ID with it if the
      # instance has been provisioned at the time the environment information
      # was read.
      #
      # Note that the ID passed in must be an integer.
      #
      # Usage example:
      #
      #   api = EY::CloudClient.new(token: 'token')
      #   env = api.environment_by_name('my_env')
      #   env.instance_by_id(12345)
      #   => <EY::CloudClient::Instance ...>
      def instance_by_id(id)
        instances.detect { |x| x.id == id } # ID should always be unique
      end

      #
      # Sends a request to the API to remove the instance specified by
      # its "provisioned_id" (Amazon ID).
      #
      # Usage example:
      #
      #   api = EY::CloudClient.new(token: 'token')
      #   env = api.environment_by_name('my_app_production')
      #   bad_instance = env.instance_by_id(12345) # instance ID should be saved upon creation
      #   env.remove_instance(bad_instance)
      #
      # Warnings/caveats:
      #
      # + The API is responsible for actually removing this instance. All this
      #   does is send an appropriate request to the API.
      # + You should look carefully at the API response JSON to see whether or
      #   not the API accepted or rejected your request. If it accepted the
      #   request, that instance *should* be removed as soon as possible.
      # + Note that this is a client that talks to an API, which talks to an
      #   API, which talks to an API. Ultimately the IaaS provider API has the
      #   final say on whether or not to remove an instance, so a failure there
      #   can definitely affect how things work at every point down the line.
      # + If the instance you pass in doesn't exist in the live cloud
      #   environment you're working on, the status should be rejected and thus
      #   the instance won't be removed (because *that* instance isn't there).
      #   This is important to keep in mind for scheduled/auto scaling; if
      #   for some reason the automatically added instance is removed before
      #   a "scale down" event that you might trigger, you may wind up with an
      #   unknown/unexpected number of instances in your environment.
      # + Only works for app/util instances. Raises an error if you pass one
      #   that isn't valid.
      def remove_instance(instance)
        unless instance
          raise ArgumentError, "A argument of type Instance was expected. Got #{instance.inspect}"
        end

        # Check to make sure that we have a valid instance role here first.
        unless %w[app util].include?(instance.role)
          raise InvalidInstanceRole, "Removing instances is only supported for app, util instances"
        end

        # Check to be sure that instance is actually provisioned
        # TODO: Rip out the amazon_id stuff when we have IaaS agnosticism nailed down
        unless instance.amazon_id && instance.provisioned?
          raise InstanceNotProvisioned, "Instance is not provisioned or is in unusual state."
        end

        response = api.post("/environments/#{id}/remove_instances", :request => {
          :provisioned_id => instance.amazon_id,
          :role => instance.role
        })

        # Reset instances so they are fresh if they are requested again.
        @instances = nil

        # Return the response.
        return response
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
