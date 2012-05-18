require 'engineyard-cloud-client/models'

module EY
  class CloudClient
    class User < ApiStruct.new(:id, :name, :email)
      def accounts
        EY::CloudClient::Account.all(api)
      end
    end
  end
end
