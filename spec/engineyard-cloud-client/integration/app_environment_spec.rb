require 'spec_helper'

describe EY::CloudClient::AppEnvironment do
  before(:each) do
    FakeWeb.allow_net_connect = true
  end

  describe ".resolve" do
    it "finds an app environment" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = api.resolve_app_environments('app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      expect(result).to be_one_match
    end

    it "finds an app environment" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve_one(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      expect(result).to be_a(EY::CloudClient::AppEnvironment)
    end

    it "returns multiple matches with ambiguous query" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets')
      expect(result).to be_many_matches
    end

    it "parses errors when there are no matches" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'notfound')
      expect(result).to be_no_matches
      expect(result.errors).not_to be_empty
    end

    it "parses errors and suggestions when there are ambiguous matches" do
      api = scenario_cloud_client "Unlinked App"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets')
      expect(result.matches).to be_empty
      expect(result.errors).not_to be_empty
      expect(result.suggestions).not_to be_empty
    end
  end

  describe "sorting" do
    it "sorts app_envs by account, app, env" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets')
      expect(result.matches.sort.map(&:hierarchy_name)).to eq([
        "account_2 / rails232app / giblets",
        "main / rails232app / giblets",
      ])
    end
  end

  describe "model" do
    before do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      expect(result).to be_one_match
      @app_env = result.matches.first
    end

    it "supplies methods to easily access names and attributes" do
      expect(@app_env.account_name).to eq('main')
      expect(@app_env.app_name).to eq('rails232app')
      expect(@app_env.environment_name).to eq('giblets')
      expect(@app_env.hierarchy_name).to eq('main / rails232app / giblets')
      expect(@app_env.repository_uri).to eq('user@git.host:path/to/repo.git')
    end
  end
end
