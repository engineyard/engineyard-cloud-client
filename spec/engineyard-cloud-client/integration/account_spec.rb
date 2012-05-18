require 'spec_helper'

describe EY::CloudClient::Account do
  before do
    FakeWeb.allow_net_connect = true
    EY::CloudClient.endpoint = EY::CloudClient::Test::FakeAwsm.uri
  end

  describe ".all" do
    it "returns all accounts" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      accounts = EY::CloudClient::Account.all(api)
      accounts.should have(2).account
      accounts.find { |account| account.name == 'main' }.should be
      accounts.find { |account| account.name == 'account_2' }.should be
    end
  end
end
