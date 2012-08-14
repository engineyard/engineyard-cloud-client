require 'engineyard-cloud-client/models/api_struct'
require 'engineyard-cloud-client/models/account'
require 'engineyard-cloud-client/models/keypair'

module EY
  class CloudClient
    class User < ApiStruct.new(:id, :name, :email)
      def accounts
        EY::CloudClient::Account.all(api)
      end

      def keypairs
        EY::CloudClient::Keypair.all(api)
      end
    end
  end
end
