require 'spec_helper'

describe EY::CloudClient::AppEnvironment do
  before(:each) do
    FakeWeb.allow_net_connect = true
    EY::CloudClient.endpoint = EY::CloudClient::Test::FakeAwsm.uri
  end

  describe ".resolve" do
    it "finds an environment" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      result.should be_one_match
    end

    it "returns multiple matches with ambiguous query" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets')
      result.should be_many_matches
    end

    it "parses errors when there are no matches" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'notfound')
      result.should be_no_matches
      result.errors.should_not be_empty
    end

    it "parses errors and suggestions when there are ambiguous matches" do
      api = scenario_cloud_client "Unlinked App"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets')
      result.matches.should be_empty
      result.errors.should_not be_empty
      result.suggestions.should_not be_empty
    end
  end

  describe "model" do
    before do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      result.should be_one_match
      @app_env = result.matches.first
    end

    it "supplies methods to easily access names and attributes" do
      @app_env.account_name.should == 'main'
      @app_env.app_name.should == 'rails232app'
      @app_env.environment_name.should == 'giblets'
      @app_env.hierarchy_name.should == 'main/rails232app/giblets'
      @app_env.repository_uri.should == 'user@git.host:path/to/repo.git'
    end
  end
end
