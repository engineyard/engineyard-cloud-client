require 'spec_helper'

describe EY::CloudClient::App do
  before(:each) do
    FakeWeb.allow_net_connect = true
    EY::CloudClient.endpoint = EY::CloudClient::Test::FakeAwsm.uri
  end

  describe ".all" do
    it "finds all the apps" do
      api = scenario_cloud_client "One App Many Envs"
      apps = EY::CloudClient::App.all(api)
      apps.size.should == 1
      app = apps.first
      app.name.should == 'rails232app'
    end

    it "includes environments in all apps" do
      api = scenario_cloud_client "One App Many Envs"
      app = EY::CloudClient::App.all(api).first
      app.environments.size.should == 2
      app.environments.map(&:name).should =~ %w[giblets bakon]
    end
  end

end
