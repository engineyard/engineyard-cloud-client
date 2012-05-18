require 'spec_helper'

describe EY::CloudClient::User do
  before do
    FakeWeb.allow_net_connect = true
    EY::CloudClient.endpoint = EY::CloudClient::Test::FakeAwsm.uri
  end

  describe ".all" do
    it "returns all accounts" do
      api = scenario_cloud_client "User Name"
      user = api.current_user
      user.name.should == 'User Name'
      user.accounts.size.should == 1
      user.accounts.first.name.should == 'main'
    end
  end
end
