require 'engineyard-cloud-client/models/api_struct'
require 'engineyard-cloud-client/errors'
require 'stringio'

module EY
  class CloudClient
    class Deployment < ApiStruct.new(:id, :app_environment, :created_at, :commit, :finished_at, :migrate_command, :ref, :resolved_ref, :successful, :user_name, :extra_config, :serverside_version)
      def self.api_root(app_id, environment_id)
        "/apps/#{app_id}/environments/#{environment_id}/deployments"
      end

      def self.last(api, app_environment)
        get(api, app_environment, 'last')
      end

      def self.get(api, app_environment, id)
        uri = api_root(app_environment.app.id, app_environment.environment.id) + "/#{id}"
        response = api.get(uri)
        load_from_response api, app_environment, response
      rescue EY::CloudClient::ResourceNotFound
        nil
      end

      def self.load_from_response(api, app_environment, response)
        dep = from_hash(api, {:app_environment => app_environment})
        dep.update_with_response(response)
        dep
      end

      def self.deploy(api, app_environment, attrs)
        Deployment.from_hash(api, attrs.merge(:app_environment => app_environment)).deploy
      end

      def app
        app_environment.app
      end

      def environment
        app_environment.environment
      end

      def migrate
        !migrate_command.nil? && !migrate_command.to_s.empty?
      end
      alias migrate? migrate
      alias migration_command migrate_command
      alias migration_command= migrate_command=

      alias successful? successful

      alias deployed_by user_name
      alias deployed_by= user_name=

      def created_at=(cat)
        if String === cat
          super Time.parse(cat)
        else
          super
        end
      end

      def finished_at=(fat)
        if String === fat
          super Time.parse(fat)
        else
          super
        end
      end

      def config
        return {} unless deployed_by # not started yet so not all info is here
        @config ||= {'input_ref' => ref, 'deployed_by' => deployed_by}.merge(extra_config)
      end

      # Tell EY Cloud that you will be starting a deploy yourself.
      #
      # The name for this method isn't great. It's a relic of how the deploy
      # ran before it ever told EY Cloud that is was running a deploy at all.
      def start
        params = {
          :migrate => migrate,
          :ref => ref,
          :serverside_version => serverside_version,
        }
        params[:migrate_command] = migrate_command if migrate
        post_to_api(params)
      end

      # Tell EY Cloud to deploy on our behalf.
      #
      # Deploy is different from start in that it triggers the deploy remotely.
      # This is almost exactly equivalent to pressing the deploy button on the
      # dashboard. No output will be returned.
      def deploy
        params = {
          :migrate => migrate,
          :ref => ref,
        }
        params[:serverside_version] = serverside_version if serverside_version
        params[:migrate_command] = migrate_command if migrate
        update_with_response api.post(collection_uri + "/deploy", 'deployment' => params)
      end

      def output
        @output ||= StringIO.new
      end

      def out
        output
      end

      def err
        output
      end

      def finished
        output.rewind
        put_to_api({:successful => successful, :output => output.read})
      end

      def cancel
        if finished?
          raise EY::CloudClient::Error, "Previous deployment is already finished. Aborting."
        else
          current_user_name = api.current_user.name
          self.successful = false
          err << "!> Marked as canceled by #{current_user_name}"
          finished
        end
      end

      def finished?
        !finished_at.nil?
      end

      def update_with_response(response)
        self.attributes = response['deployment']
        self
      end

      private

      def post_to_api(params)
        update_with_response api.post(collection_uri, 'deployment' => params)
      end

      def put_to_api(params)
        update_with_response api.put(member_uri("/finished"), 'deployment' => params)
      end

      def collection_uri
        self.class.api_root(app.id, environment.id)
      end

      def member_uri(path = nil)
        collection_uri + "/#{id}#{path}"
      end
    end
  end
end
