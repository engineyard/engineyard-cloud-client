require 'spec_helper'

describe EY::CloudClient::Environment do
  before(:each) do
    FakeWeb.allow_net_connect = true
    EY::CloudClient.endpoint = EY.fake_awsm
  end

  describe ".resolve" do
    it "finds an environment" do
      api = api_scenario "Multiple Ambiguous Accounts"
      result = EY::CloudClient::Environment.resolve(api, 'environment_name' => 'giblets', 'account_name' => 'main' )
      result.should be_one_match
    end

    it "returns multiple matches with ambiguous query" do
      api = api_scenario "Multiple Ambiguous Accounts"
      result = EY::CloudClient::Environment.resolve(api, 'environment_name' => 'giblets' )
      result.should be_many_matches
    end

    it "parses errors when there are no matches" do
      api = api_scenario "Multiple Ambiguous Accounts"
      result = EY::CloudClient::Environment.resolve(api, 'environment_name' => 'notfound' )
      result.should be_no_matches
      result.errors.should_not be_empty
    end

    it "parses errors and suggestions when there are ambiguous matches" do
      api = api_scenario "Unlinked App"
      result = EY::CloudClient::Environment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets' )
      result.should be_no_matches
      result.errors.should_not be_empty
      result.suggestions.should_not be_empty
    end
  end

end
