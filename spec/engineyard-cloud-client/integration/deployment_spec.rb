require 'spec_helper'

describe EY::CloudClient::AppEnvironment do
  before(:each) do
    FakeWeb.allow_net_connect = true
    EY::CloudClient.endpoint = EY::CloudClient::Test::FakeAwsm.uri
  end

  describe "deploying" do
    it "creates a deployment" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      result.should be_one_match
      app_env = result.matches.first
      deployment = app_env.new_deployment({
        :ref             => 'master',
        :migrate         => true,
        :migrate_command => 'rake migrate',
        :extra_config    => {},
      })
      deployment.commit.should be_nil
      deployment.resolved_ref.should be_nil

      deployment.start

      deployment.commit.should_not be_nil
      deployment.resolved_ref.should_not be_nil
      deployment.out << "Test output"
      deployment.successful = true
      deployment.finished
      deployment.should be_finished

      found_dep = app_env.last_deployment
      found_dep.id.should == deployment.id
      found_dep.should be_finished
    end
  end
end
