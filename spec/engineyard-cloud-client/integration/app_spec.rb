require 'spec_helper'

describe EY::CloudClient::App do
  before(:each) do
    WebMock.allow_net_connect!
  end

  describe ".all" do
    it "finds all the apps" do
      api = scenario_cloud_client "One App Many Envs"
      apps = EY::CloudClient::App.all(api)
      expect(apps.size).to eq(1)
      app = apps.first
      expect(app.name).to eq('rails232app')
    end

    it "includes environments in all apps" do
      api = scenario_cloud_client "One App Many Envs"
      app = api.apps.first
      expect(app.environments.size).to eq(2)
      expect(app.environments.sort.map(&:name)).to match_array(%w[bakon giblets])
    end
  end

end
