require 'spec_helper'

describe EY::CloudClient::Environment do
  before(:each) do
    FakeWeb.allow_net_connect = true
  end

  describe ".all" do
    it "finds all the environments" do
      api = scenario_cloud_client "One App Many Envs"
      envs = EY::CloudClient::Environment.all(api)
      envs.size.should == 3
      envs.map(&:name).should =~ %w[giblets bakon beef]
      envs.map(&:username).should =~ %w[turkey ham hamburger]
      envs.map(&:account_name).uniq.should == ['main']
      with_instances = envs.select {|env| env.instances_count > 0 }
      with_instances.size.should == 1
      with_instances.first.instances.map(&:amazon_id).should == ['i-ddbbdd92']
    end

    it "includes apps in environments" do
      api = scenario_cloud_client "One App Many Envs"
      envs = api.environments
      envs.map do |env|
        env.apps.first && env.apps.first.name
      end.should == ['rails232app', 'rails232app', nil] # 2 envs with the same app, 1 without
    end
  end

  describe ".resolve" do
    it "finds an environment" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = api.resolve_environments('environment_name' => 'giblets', 'account_name' => 'main' )
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

  describe "api.environment_by_name / Environment.by_name / api.env_by_name" do
    it "finds an environment" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      result = api.environment_by_name('giblets', 'main')
      result.should be_a_kind_of(EY::CloudClient::Environment)
      result.name.should == 'giblets'
      result.account.name.should == 'main'
    end

    it "raises on ambiguous query" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      expect { EY::CloudClient::Environment.by_name(api, 'giblets') }.to raise_error(EY::CloudClient::MultipleMatchesError)
    end

    it "raises when env doesn't exist" do
      api = scenario_cloud_client "Multiple Ambiguous Accounts"
      expect { api.env_by_name('gobblegobble') }.to raise_error(EY::CloudClient::ResourceNotFound)
    end
  end

  context "with an environment" do
    before do
      api = scenario_cloud_client "Linked App"
      result = EY::CloudClient::Environment.resolve(api, 'account_name' => 'main', 'app_name' => 'rails232app', 'environment_name' => 'giblets')
      @env = result.matches.first
    end

    it "requests instances when needed" do
      @env.bridge.role.should == 'app_master'
      @env.instances.size.should == @env.instances_count
    end

    it "doesn't request when instances_count is zero" do
      api = scenario_cloud_client "Linked App Not Running"
      result = EY::CloudClient::Environment.resolve(api, 'account_name' => 'main', 'app_name' => 'rails232app', 'environment_name' => 'giblets')
      @env = result.matches.first
      @env.instances_count.should == 0
      @env.instances.should == []
    end

    it "selects deploy_to_instances" do
      @env.deploy_to_instances.map(&:role).should =~ %w[app_master app util util]
    end

    def expect_instances(instances)
      expect(instances.map { |i| [i.role, i.name, i.public_hostname] })
    end

    it "sorts instances" do
      expect_instances(@env.instances).to eq([
        ["app_master", nil,       "app_master_hostname.compute-1.amazonaws.com"],
        ["app",        nil,              "app_hostname.compute-1.amazonaws.com"],
        ["db_master",  nil,        "db_master_hostname.compute-1.amazonaws.com"],
        ["db_slave",   "Slave I", "db_slave_1_hostname.compute-1.amazonaws.com"],
        ["db_slave",   nil,       "db_slave_2_hostname.compute-1.amazonaws.com"],
        ["util" ,      "fluffy", "util_fluffy_hostname.compute-1.amazonaws.com"],
        ["util",       "rocky",   "util_rocky_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "finds no instances by role solo" do
      expect(@env.select_instances(solo: true)).to be_empty
    end

    it "selects instances by solo, app, app_master" do
      expect_instances(@env.select_instances(solo: true, app: true, app_master: true)).to eq([
        ["app_master", nil,       "app_master_hostname.compute-1.amazonaws.com"],
        ["app",        nil,              "app_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "selects instances by solo, app, app_master, util" do
      expect_instances(@env.select_instances(solo: true, app: true, app_master: true, util: true)).to eq([
        ["app_master", nil,       "app_master_hostname.compute-1.amazonaws.com"],
        ["app",        nil,              "app_hostname.compute-1.amazonaws.com"],
        ["util" ,      "fluffy", "util_fluffy_hostname.compute-1.amazonaws.com"],
        ["util",       "rocky",   "util_rocky_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "selects instances by util with name string" do
      expect_instances(@env.select_instances(util: "rocky")).to eq([
        ["util",       "rocky",   "util_rocky_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "selects instances by util with name array" do
      expect_instances(@env.select_instances(util: %w[fluffy rocky])).to eq([
        ["util" ,      "fluffy", "util_fluffy_hostname.compute-1.amazonaws.com"],
        ["util",       "rocky",   "util_rocky_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "selects instances by solo, app, or util with name string" do
      expect_instances(@env.select_instances(solo: true, app: true, util: "rocky")).to eq([
        ["app",        nil,              "app_hostname.compute-1.amazonaws.com"],
        ["util",       "rocky",   "util_rocky_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "selects instances by solo, db_master, db_slave" do
      expect_instances(@env.select_instances(solo: true, db_master: true, db_slave: true)).to eq([
        ["db_master",  nil,        "db_master_hostname.compute-1.amazonaws.com"],
        ["db_slave",   "Slave I", "db_slave_1_hostname.compute-1.amazonaws.com"],
        ["db_slave",   nil,       "db_slave_2_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "finds instances by role solo, db_master, or db_slave with the specified name only" do
      expect_instances(@env.select_instances(solo: true, db_master: true, db_slave: "Slave I")).to eq([
        ["db_master",  nil,        "db_master_hostname.compute-1.amazonaws.com"],
        ["db_slave",   "Slave I", "db_slave_1_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "finds instances by role solo, db_master, or db_slave with blank name only" do
      expect_instances(@env.select_instances(solo: true, db_master: true, db_slave: "")).to eq([
        ["db_master",  nil,        "db_master_hostname.compute-1.amazonaws.com"],
        ["db_slave",   nil,       "db_slave_2_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "selects instances by app, excluding app_master" do
      expect_instances(@env.select_instances(app: true, app_master: false)).to eq([
        ["app",        nil,              "app_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "finds solo, app, app_master, util" do
      expect_instances(@env.instances_by_role(:solo, :app, :app_master, :util)).to eq([
        ["app_master", nil,       "app_master_hostname.compute-1.amazonaws.com"],
        ["app",        nil,              "app_hostname.compute-1.amazonaws.com"],
        ["util" ,      "fluffy", "util_fluffy_hostname.compute-1.amazonaws.com"],
        ["util",       "rocky",   "util_rocky_hostname.compute-1.amazonaws.com"],
      ])
    end

    it "updates the environment" do
      @env.update.should be_true
    end

    it "runs custom recipes" do
      @env.run_custom_recipes.should be_true
    end

    it "uploads recipes" do
      res = @env.upload_recipes(Pathname.new('spec/support/fixture_recipes.tgz').expand_path.open('rb'))
      res.should be_true
    end

    it "uploads recipes at path" do
      res = @env.upload_recipes_at_path(Pathname.new('spec/support/fixture_recipes.tgz').expand_path.to_s)
      res.should be_true
    end

    it "raises if uploads recipes path doesn't exist" do
      path = Pathname.new('spec/support/nothing')
      lambda {
        @env.upload_recipes_at_path(path)
      }.should raise_error(EY::CloudClient::Error, "Recipes file not found: #{path}")
    end

    it "downloads recipes" do
      @env.download_recipes
    end

    it "returns logs" do
      log = @env.logs.first
      log.main.should == 'MAIN LOG OUTPUT'
      log.custom.should == 'CUSTOM LOG OUTPUT'
      log.role.should == 'app_master'
      log.instance_name.should == "app_master i-12345678"
    end
  end

end
