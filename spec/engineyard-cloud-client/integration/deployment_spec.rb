require 'spec_helper'

describe EY::CloudClient::AppEnvironment do
  before(:each) do
    FakeWeb.allow_net_connect = true
  end

  describe "deploying" do
    before do
      @api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(@api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      result.should be_one_match
      @app_env = result.matches.first
    end

    it "creates a deployment" do
      deployment = @app_env.new_deployment({
        :ref             => 'master',
        :migrate         => true,
        :migrate_command => 'rake migrate',
        :extra_config    => {'extra' => 'config'},
        :serverside_version => '2.0.3',
      })
      deployment.commit.should be_nil
      deployment.resolved_ref.should be_nil
      deployment.serverside_version.should == '2.0.3'

      deployment.created_at.should be_nil
      deployment.finished_at.should be_nil

      deployment.start

      deployment.created_at.should_not be_nil
      deployment.finished_at.should be_nil
      deployment.config.should == {'input_ref' => 'master', 'deployed_by' => 'Multiple Ambiguous Accounts', 'extra' => 'config'}
      deployment.commit.should =~ /[0-9a-f]{40}/
      deployment.resolved_ref.should_not be_nil
      deployment.out << "Test output"
      deployment.out << "Test error"
      deployment.successful = true

      deployment.finished

      deployment.should be_finished
      deployment.created_at.should be_within(5).of(Time.now)
      deployment.finished_at.should be_within(5).of(Time.now)

      found_dep = @app_env.last_deployment
      found_dep.id.should == deployment.id
      found_dep.should be_finished
      found_dep.serverside_version.should == '2.0.3'
    end

    it "returns nil when a not found deployment is requested" do
      EY::CloudClient::Deployment.get(@api, @app_env, 0).should be_nil
    end
  end

  describe "triggering an api deploy" do
    before do
      @api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(@api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      result.should be_one_match
      @app_env = result.matches.first
    end

    it "triggers a deployment (assumes that deploys happen instantly, which they don't)" do
      deployment = @app_env.deploy({
        :ref             => 'master',
        :migrate         => true,
        :migrate_command => 'rake migrate',
        :extra_config    => {'extra' => 'config'},
      })
      deployment.config.should == {'input_ref' => 'master', 'deployed_by' => 'Multiple Ambiguous Accounts', 'extra' => 'config'}
      deployment.commit.should =~ /[0-9a-f]{40}/
      deployment.resolved_ref.should_not be_nil
      deployment.created_at.should_not be_nil
      deployment.finished_at.should_not be_nil
      deployment.should be_finished

      found_dep = @app_env.last_deployment
      found_dep.id.should == deployment.id
      found_dep.should be_finished
      found_dep.serverside_version.should == '2.0.0.awsm' # uses the awsm version if one is not sent.
    end
  end

  describe "last deployment" do
    before do
      @api = scenario_cloud_client "Linked App"
      result = EY::CloudClient::AppEnvironment.resolve(@api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      result.should be_one_match
      @app_env = result.matches.first
    end

    it "returns nil when there have been no deployments" do
      EY::CloudClient::Deployment.last(@api, @app_env).should be_nil
    end

    it "returns the last deployment when there has been at least one" do
      deployment = @app_env.new_deployment({
        :ref             => 'master',
        :migrate         => true,
        :migrate_command => 'rake migrate',
      })
      deployment.start
      deployment.out << "Test output"
      deployment.successful = true
      deployment.finished
      EY::CloudClient::Deployment.last(@api, @app_env).should == deployment
    end
  end
end
