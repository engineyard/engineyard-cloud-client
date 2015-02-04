require 'spec_helper'

describe EY::CloudClient::Keypair do
  before do
    FakeWeb.allow_net_connect = true
  end

  it "creates, finds, and destroys keypairs" do
    api = scenario_cloud_client "User Name"
    keypair = EY::CloudClient::Keypair.create(api, {
        "name"       => 'laptop',
        "public_key" => "ssh-rsa OTHERKEYPAIR"
    })

    expect(keypair.name).to eq("laptop")
    expect(keypair.public_key).to eq("ssh-rsa OTHERKEYPAIR")

    keypairs = EY::CloudClient::Keypair.all(api)
    expect(keypairs).to match_array([keypair])

    keypair.destroy
  end
end
