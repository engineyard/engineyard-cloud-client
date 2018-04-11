require 'spec_helper'

describe EY::CloudClient::User do
  before do
    WebMock.allow_net_connect!
  end

  it "loads current user and returns all accounts" do
    api = scenario_cloud_client "User Name"
    user = api.current_user
    expect(user.name).to eq('User Name')
    expect(user.accounts.size).to eq(1)
    expect(user.accounts.first.name).to eq('main')
  end

  it "has keypairs" do
    api = scenario_cloud_client "User Name"
    keypair = EY::CloudClient::Keypair.create(api, {
        "name"       => 'laptop',
        "public_key" => "ssh-rsa OTHERKEYPAIR"
    })
    expect(api.current_user.keypairs).to include(keypair)
    keypair.destroy
  end
end
