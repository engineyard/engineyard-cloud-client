require 'tempfile'
require 'engineyard-cloud-client/errors'

module EY
  class CloudClient
    class Recipes
      attr_reader :api, :environment

      def initialize(api, environment)
        @api = api
        @environment = environment
      end

      def run
        api.put("/environments/#{environment.id}/run_custom_recipes")
        true
      end

      def download
        tmp = Tempfile.new("recipes")
        data = api.get("/environments/#{environment.id}/recipes")
        tmp.write(data)
        tmp.flush
        tmp.close
        tmp
      end

      def upload_path(recipes_path)
        recipes_path = Pathname.new(recipes_path)
        if recipes_path.exist?
          upload recipes_path.open('rb')
        else
          raise EY::CloudClient::Error, "Recipes file not found: #{recipes_path}"
        end
      end

      # Expects a File object opened for binary reading.
      # i.e. upload(File.open(recipes_path, 'rb'))
      def upload(file_to_upload)
        api.post("/environments/#{environment.id}/recipes", :file => file_to_upload)
        true
      end

    end
  end
end
