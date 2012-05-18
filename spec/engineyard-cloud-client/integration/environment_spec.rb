require 'spec_helper'

describe EY::CloudClient::Environment do
  before(:each) do
    FakeWeb.allow_net_connect = true
    EY::CloudClient.endpoint = EY::CloudClient::Test::FakeAwsm.uri
  end

  describe ".all" do
    it "finds all the environments" do
      api = scenario_cloud_client "One App Many Envs"
      envs = EY::CloudClient::Environment.all(api)
      envs.size.should == 3
      envs.map(&:name).should =~ %w[giblets bakon beef]
    end
  end

  describe ".resolve" do
    it "finds an environment" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::Environment.resolve(api, 'environment_name' => 'giblets', 'account_name' => 'main' )
      result.should be_one_match
    end

    it "returns multiple matches with ambiguous query" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::Environment.resolve(api, 'environment_name' => 'giblets' )
      result.should be_many_matches
    end

    it "parses errors when there are no matches" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::Environment.resolve(api, 'environment_name' => 'notfound' )
      result.should be_no_matches
      result.errors.should_not be_empty
    end

    it "parses errors and suggestions when there are ambiguous matches" do
      api = scenario_cloud_client "Unlinked App"
      result = EY::CloudClient::Environment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets' )
      result.should be_no_matches
      result.errors.should_not be_empty
      result.suggestions.should_not be_empty
    end
  end

  describe "loading instances" do
    it "requests instances" do
      api = scenario_cloud_client "Linked App"
      result = EY::CloudClient::Environment.resolve(api, 'account_name' => 'main', 'app_name' => 'rails232app', 'environment_name' => 'giblets')
      env = result.matches.first
      env.bridge.role.should == 'app_master'
      env.instances.size.should == env.instances_count
    end
  end

end
