require 'engineyard-cloud-client/models/api_struct'
require 'engineyard-cloud-client/models/account'

module EY
  class CloudClient
    class User < ApiStruct.new(:id, :name, :email)
      def accounts
        EY::CloudClient::Account.all(api)
      end
    end
  end
end
