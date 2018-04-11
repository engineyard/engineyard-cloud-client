require 'spec_helper'

describe EY::CloudClient::Account do
  before do
    WebMock.allow_net_connect!
  end

  describe ".all" do
    it "returns all accounts" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      accounts = EY::CloudClient::Account.all(api)
      expect(accounts.size).to eq(2)
      expect(accounts.sort).to eq([
        accounts.find { |account| account.name == 'account_2' },
        accounts.find { |account| account.name == 'main' },
      ])
    end
  end
end
