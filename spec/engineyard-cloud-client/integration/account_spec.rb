require 'spec_helper'

describe EY::CloudClient::Account do
  before(:all) do
    FakeWeb.allow_net_connect = true
  end

  describe ".all" do
    it "returns all accounts" do
      EY::CloudClient.endpoint = EY.fake_awsm
      api = api_scenario "Multiple Ambiguous Accounts"
      accounts = EY::CloudClient::Account.all(api)
      accounts.should have(2).account
      accounts.find { |account| account.name == 'main' }.should be
      accounts.find { |account| account.name == 'account_2' }.should be
    end
  end
end
