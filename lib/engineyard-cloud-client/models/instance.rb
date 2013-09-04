require 'engineyard-cloud-client/models/api_struct'

module EY
  class CloudClient
    class Instance < ApiStruct.new(:id, :role, :name, :status, :amazon_id, :public_hostname, :environment, :bridge, :availability_zone)
      alias hostname public_hostname
      alias bridge? bridge

      def has_app_code?
        !["db_master", "db_slave"].include?(role.to_s)
      end

      def running?
        status == "running"
      end

      def provisioned?
        hostname && role && status != "starting" # not foolproof, but help throw out bad instances
      end

      def remove
        environment.remove_instance(self)
      end

      def sort_attributes
        # Shift app_master above app since that's how it's usually shown
        sort_role = role == 'app' ? 'app_slave' : role
        [sort_string(sort_role), sort_string(name), sort_string(hostname)]
      end

    end
  end
end
