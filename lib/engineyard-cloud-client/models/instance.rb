require 'engineyard-cloud-client/models/api_struct'

module EY
  class CloudClient
    class Instance < ApiStruct.new(:id, :role, :name, :status, :amazon_id, :public_hostname, :environment, :bridge)
      alias hostname public_hostname
      alias bridge? bridge

      def has_app_code?
        !["db_master", "db_slave"].include?(role.to_s)
      end

    end
  end
end
