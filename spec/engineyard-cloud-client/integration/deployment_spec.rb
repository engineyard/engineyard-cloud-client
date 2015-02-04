require 'spec_helper'

describe EY::CloudClient::AppEnvironment do
  before(:each) do
    FakeWeb.allow_net_connect = true
  end

  describe "deploying" do
    before do
      @api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(@api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      expect(result).to be_one_match
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
      expect(deployment.commit).to be_nil
      expect(deployment.resolved_ref).to be_nil
      expect(deployment.serverside_version).to eq('2.0.3')

      expect(deployment.created_at).to be_nil
      expect(deployment.finished_at).to be_nil

      deployment.start

      expect(deployment.created_at).not_to be_nil
      expect(deployment.finished_at).to be_nil
      expect(deployment.config).to eq({'input_ref' => 'master', 'deployed_by' => 'Multiple Ambiguous Accounts', 'extra' => 'config'})
      expect(deployment.commit).to match(/[0-9a-f]{40}/)
      expect(deployment.resolved_ref).not_to be_nil
      deployment.out << "Test output"
      deployment.out << "Test error"
      deployment.successful = true

      deployment.finished

      expect(deployment).to be_finished
      expect(deployment.created_at).to be_within(5).of(Time.now)
      expect(deployment.finished_at).to be_within(5).of(Time.now)

      found_dep = @app_env.last_deployment
      expect(found_dep.id).to eq(deployment.id)
      expect(found_dep).to be_finished
      expect(found_dep.serverside_version).to eq('2.0.3')
    end

    it "returns nil when a not found deployment is requested" do
      expect(EY::CloudClient::Deployment.get(@api, @app_env, 0)).to be_nil
    end
  end

  describe "triggering an api deploy" do
    before do
      @api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = EY::CloudClient::AppEnvironment.resolve(@api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      expect(result).to be_one_match
      @app_env = result.matches.first
    end

    it "triggers a deployment (assumes that deploys happen instantly, which they don't)" do
      deployment = @app_env.deploy({
        :ref             => 'master',
        :migrate         => true,
        :migrate_command => 'rake migrate',
        :extra_config    => {'extra' => 'config'},
      })
      expect(deployment.config).to eq({'input_ref' => 'master', 'deployed_by' => 'Multiple Ambiguous Accounts', 'extra' => 'config'})
      expect(deployment.commit).to match(/[0-9a-f]{40}/)
      expect(deployment.resolved_ref).not_to be_nil
      expect(deployment.created_at).not_to be_nil
      expect(deployment.finished_at).not_to be_nil
      expect(deployment).to be_finished

      found_dep = @app_env.last_deployment
      expect(found_dep.id).to eq(deployment.id)
      expect(found_dep).to be_finished
      expect(found_dep.serverside_version).to eq('2.0.0.awsm') # uses the awsm version if one is not sent.
    end
  end

  describe "last deployment" do
    before do
      @api = scenario_cloud_client "Linked App"
      result = EY::CloudClient::AppEnvironment.resolve(@api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      expect(result).to be_one_match
      @app_env = result.matches.first
    end

    it "returns nil when there have been no deployments" do
      expect(EY::CloudClient::Deployment.last(@api, @app_env)).to be_nil
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
      expect(EY::CloudClient::Deployment.last(@api, @app_env)).to eq(deployment)
    end
  end

  describe "timing out (canceling)" do
    before do
      @api = scenario_cloud_client "Stuck Deployment"
      result = EY::CloudClient::AppEnvironment.resolve(@api, 'app_name' => 'rails232app', 'environment_name' => 'giblets', 'account_name' => 'main')
      expect(result).to be_one_match
      @app_env = result.matches.first
    end

    it "marks the deployment finish and unsuccessful with a message" do
      deployment = EY::CloudClient::Deployment.last(@api, @app_env)
      expect(deployment).not_to be_finished
      deployment.timeout
      expect(deployment).to be_finished
      expect(deployment).not_to be_successful
      deployment.output.rewind
      expect(deployment.output.read).to match(/Marked as timed out by Stuck Deployment/)

      expect(EY::CloudClient::Deployment.last(@api, @app_env)).to be_finished
    end

    it "raises if the deployment is already finished" do
      deployment = EY::CloudClient::Deployment.last(@api, @app_env)
      deployment.out << "Test output"
      deployment.successful = true
      deployment.finished
      expect(deployment).to be_finished
      expect { deployment.timeout }.to raise_error(EY::CloudClient::Error, "Previous deployment is already finished. Aborting.")
    end
  end
end
