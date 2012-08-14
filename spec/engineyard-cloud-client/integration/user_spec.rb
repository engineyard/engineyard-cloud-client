require 'spec_helper'

describe EY::CloudClient::User do
  before do
    FakeWeb.allow_net_connect = true
  end

  it "loads current user and returns all accounts" do
    api = scenario_cloud_client "User Name"
    user = api.current_user
    user.name.should == 'User Name'
    user.accounts.size.should == 1
    user.accounts.first.name.should == 'main'
  end

  it "has keypairs" do
    api = scenario_cloud_client "User Name"
    keypair = EY::CloudClient::Keypair.create(api, {
        "name"       => 'laptop',
        "public_key" => "ssh-rsa OTHERKEYPAIR"
    })
    api.current_user.keypairs.should include(keypair)
    keypair.destroy
  end
end
