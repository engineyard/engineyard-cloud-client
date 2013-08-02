require 'spec_helper'

describe EY::CloudClient::Environment do

  describe ".all" do
    it "hits the index action in the API" do
      response = {
        "environments" => [
          {"apps"=>
            [{"name"=>"myapp",
              "repository_uri"=>"git@github.com:myaccount/myapp.git",
              "account"=>{"name"=>"myaccount", "id"=>1234},
              "id"=>12345}],
           "name"=>"myapp_production",
           "deployment_configurations"=>
            {"myapp"=>
              {"name"=>"myapp",
               "uri"=>nil,
               "migrate"=>{"command"=>"rake db:migrate", "perform"=>true},
               "repository_uri"=>"git@github.com:myaccount/myapp.git",
               "id"=>12345,
               "domain_name"=>"_"}},
           "instances"=>[],
           "app_master"=>nil,
           "framework_env"=>"production",
           "stack_name"=>"nginx_thin",
           "account"=>{"name"=>"myaccount", "id"=>1234},
           "app_server_stack_name"=>"nginx_thin",
           "ssh_username"=>"deploy",
           "load_balancer_ip_address"=>nil,
           "instances_count"=>0,
           "id"=>30573,
           "instance_status"=>"none"
          }
        ]
      }

      FakeWeb.register_uri(:get, "https://cloud.engineyard.com/api/v2/environments?no_instances=true",
        :body => MultiJson.dump(response), :content_type => "application/json")

      environments = EY::CloudClient::Environment.all(cloud_client)

      environments.length.should == 1
      environments.first.name.should == "myapp_production"
    end
  end

  describe ".create" do
    it "hits the create action in the API without any cluster configuration (0 instances booted)" do
      account = EY::CloudClient::Account.new(cloud_client, {:id => 1234, :name => 'myaccount'})
      app = EY::CloudClient::App.new(cloud_client, {:account => account, :id => 12345, :name => 'myapp',
        :repository_uri => 'git@github.com:myaccount/myapp.git', :app_type_id => 'rails3'})

      response =   {
        "environment"=>
          {"apps"=>
            [{"name"=>"myapp",
              "repository_uri"=>"git@github.com:myaccount/myapp.git",
              "account"=>{"name"=>"myaccount", "id"=>1234},
              "id"=>12345}],
           "name"=>"myapp_production",
           "deployment_configurations"=>
            {"myapp"=>
              {"name"=>"myapp",
               "uri"=>nil,
               "migrate"=>{"command"=>"rake db:migrate", "perform"=>true},
               "repository_uri"=>"git@github.com:myaccount/myapp.git",
               "id"=>12345,
               "domain_name"=>"_"}},
           "instances"=>[],
           "app_master"=>nil,
           "framework_env"=>"production",
           "stack_name"=>"nginx_thin",
           "account"=>{"name"=>"myaccount", "id"=>1234},
           "app_server_stack_name"=>"nginx_thin",
           "ssh_username"=>"deploy",
           "load_balancer_ip_address"=>nil,
           "instances_count"=>0,
           "id"=>30573,
           "instance_status"=>"none"}}

      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments",
        :body => MultiJson.dump(response), :content_type => "application/json")

      env = EY::CloudClient::Environment.create(cloud_client, {
        "app"                   => app,
        "name"                  => 'myapp_production',
        "app_server_stack_name" => 'nginx_thin',
        "region"                => 'us-west-1'
      })
      FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments")

      env.name.should == "myapp_production"
      env.account.name.should == "myaccount"
      env.apps.to_a.first.name.should == "myapp"
    end

    it "hits the create action and requests a solo instance booted" do
      account = EY::CloudClient::Account.from_hash(cloud_client, {:id => 1234, :name => 'myaccount'})
      app = EY::CloudClient::App.from_hash(cloud_client, {:account => account, :id => 12345, :name => 'myapp',
        :repository_uri => 'git@github.com:myaccount/myapp.git', :app_type_id => 'rails3'})

      response =   {
        "environment"=>
          {"apps"=>
            [{"name"=>"myapp",
              "repository_uri"=>"git@github.com:myaccount/myapp.git",
              "account"=>{"name"=>"myaccount", "id"=>1234},
              "id"=>12345}],
           "name"=>"myapp_production",
           "deployment_configurations"=>
            {"myapp"=>
              {"name"=>"myapp",
               "uri"=>nil,
               "migrate"=>{"command"=>"rake db:migrate", "perform"=>true},
               "repository_uri"=>"git@github.com:myaccount/myapp.git",
               "id"=>12345,
               "domain_name"=>"_"}},
           "instances"=>
             [{"public_hostname"=>nil,
               "name"=>nil,
               "amazon_id"=>nil,
               "role"=>"solo",
               "bridge"=>true,
               "id"=>135930,
               "status"=>"starting"}],
            "app_master"=>
             {"public_hostname"=>nil,
              "name"=>nil,
              "amazon_id"=>nil,
              "role"=>"solo",
              "bridge"=>true,
              "id"=>135930,
              "status"=>"starting"},
           "framework_env"=>"production",
           "stack_name"=>"nginx_thin",
           "account"=>{"name"=>"myaccount", "id"=>1234},
           "app_server_stack_name"=>"nginx_thin",
           "ssh_username"=>"deploy",
           "load_balancer_ip_address"=>"50.18.248.18",
           "instances_count"=>1,
           "id"=>30573,
           "instance_status"=>"starting"}}

      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments",
        :body => MultiJson.dump(response), :content_type => "application/json")

      env = EY::CloudClient::Environment.create(cloud_client, {
        "app"                   => app,
        "name"                  => "myapp_production",
        "app_server_stack_name" => "nginx_thin",
        "region"                => "us-west-1",
        "cluster_configuration" => {
          "configuration" => "solo"
        }
      })
      FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments")

      env.name.should == "myapp_production"
      env.instances.count.should == 1
      env.bridge.role.should == "solo"
    end
  end

  describe "#rebuild" do
    it "hits the rebuild action in the API" do
      env = EY::CloudClient::Environment.from_hash(cloud_client, { "id" => 46534 })

      FakeWeb.register_uri(
        :put,
        "https://cloud.engineyard.com/api/v2/environments/#{env.id}/update_instances",
        :body => ''
      )

      env.rebuild

      FakeWeb.should have_requested(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/update_instances")
    end
  end

  describe "#run_custom_recipes" do
    it "hits the rebuild action in the API" do
      env = EY::CloudClient::Environment.from_hash(cloud_client, { "id" => 46534 })

      FakeWeb.register_uri(
        :put,
        "https://cloud.engineyard.com/api/v2/environments/#{env.id}/run_custom_recipes",
        :body => '',
        :content_type => 'application/json'
      )

      env.run_custom_recipes

      FakeWeb.should have_requested(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/run_custom_recipes")
    end
  end

  describe "#instances" do
    it "returns instances" do
      instance_data = {
        "id" => "1",
        "role" => "app_master",
        "bridge" => true,
        "amazon_id" => "i-likebeer",
        "public_hostname" => "banana_master"
      }

      env = EY::CloudClient::Environment.from_hash(cloud_client, {
        "id" => 10291,
        "instances" => [instance_data],
      })

      FakeWeb.register_uri(:get,
        "https://cloud.engineyard.com/api/v2/environments/#{env.id}/instances",
        :body => MultiJson.dump({"instances" => [instance_data]}),
        :content_type => 'application/json'
      )

      env.should have(1).instances
      env.instances.first.should == EY::CloudClient::Instance.from_hash(cloud_client, instance_data.merge('environment' => env))
    end
  end

  describe "#bridge!" do
    def make_env_with_bridge(bridge)
      if bridge
        bridge = {
          "id" => 44206,
          "role" => "solo",
          "bridge" => true,
        }.merge(bridge)
      end

      EY::CloudClient::Environment.from_hash(cloud_client, {
        "id" => 11830,
        "name" => "guinea-pigs-are-delicious",
        "app_master" => bridge,
        "instances" => [bridge].compact,
      })
    end


    it "returns the bridge if it's present and running" do
      env = make_env_with_bridge("status" => "running")
      env.bridge!.should_not be_nil
      env.bridge!.id.should == 44206
    end

    it "raises an error if the bridge is in a non-running state" do
      env = make_env_with_bridge("status" => "error")
      lambda {
        env.bridge!
      }.should raise_error(EY::CloudClient::BadBridgeStatusError)
    end

    it "returns the bridge if told to ignore the bridge being in a non-running state" do
      env = make_env_with_bridge("status" => "error")
      ignore_bad_bridge = true
      env.bridge!(ignore_bad_bridge).should_not be_nil
      env.bridge!(ignore_bad_bridge).id.should == 44206
    end

    it "raises an error if the bridge has fallen down" do
      env = make_env_with_bridge(nil)
      lambda {
        env.bridge!
      }.should raise_error(EY::CloudClient::NoBridgeError)
    end
  end

  describe "#shorten_name_for(app)" do
    def short(environment_name, app_name)
      env = EY::CloudClient::Environment.from_hash(cloud_client, {'name' => environment_name})
      app = EY::CloudClient::App.from_hash(cloud_client, {'name' => app_name})
      env.shorten_name_for(app)
    end

    it "turns myapp+myapp_production to production" do
      short('myapp_production', 'myapp').should == 'production'
    end

    it "turns product+production to production (leaves it alone)" do
      short('production', 'product').should == 'production'
    end

    it "leaves the environment name alone when the app name appears in the middle" do
      short('hattery', 'ate').should == 'hattery'
    end

    it "does not produce an empty string when the names are the same" do
      short('dev', 'dev').should == 'dev'
    end
  end

  describe "#remove_instance(instance)" do
    before :all do
      @env = EY::CloudClient::Environment.from_hash(
        EY::CloudClient.new(token: 't'),
        {
          'name' => 'fake',
          'id' => '123',
          'instances_count' => 4,
          'instances' => [
            {
              'id' => 12345,
              'role' => 'app'
            },
            {
              'id' => 54321,
              'role' => 'util'
            },
            {
              'id' => 8675309,
              'role' => 'db_master'
            },
            {
              'id' => 55555,
              'role' => 'app',
              'public_hostname' => 'some-hostname',
              'status' => 'running',
              'amazon_id' => 'i-xxxxxxx'
            }
          ]
        }
      )

      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances",
        body: '{
          "request"  => {"provisioned_id"=>"i-xxxxxx", "role"=>"app"},
          "instance" => {"amazon_id"=>"i-xxxxxxx" "id"=>12345, "role"=>"app", "status"=>"running"},
          "status"=>"accepted"
        }')

      # For the end of the remove method, getting new instance data
      FakeWeb.register_uri(:get, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/instances?",
        body: '{[{"id": 12345,"role": "app"}]}')
    end

    after :all do
      @env = nil # clean up
    end

    it "raises an error if role isn't app/util" do
      i = @env.instance_by_id(8675309)
      expect {
        @env.remove_instance(i) # db_master, should fail
      }.to raise_error EY::CloudClient::InvalidInstanceRole
      FakeWeb.should_not have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances")
    end

    it "raises an error if the instance isn't provisioned yet" do
      i = @env.instance_by_id(12345)
      expect {
        @env.remove_instance(i) # app, but not provisioned and no amazon id
      }.to raise_error EY::CloudClient::InstanceNotProvisioned
      FakeWeb.should_not have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances")
    end

    it "sends an API request when things check out" do
      i = @env.instance_by_id(55555) # known good instance as defined above
      expect {
        @env.remove_instance(i)
      }.to_not raise_error
      FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances")
    end
  end

  describe "#add_instances(name: 'foo', role: 'app')" do
    before :all do
      @env = EY::CloudClient::Environment.from_hash(
        EY::CloudClient.new(token: 't'), {'name' => 'fake', "id" => "123"} )

      # Register the API endpoint with FakeWeb
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances",
        body: '{
            "request"=>{"role"=>"app", "name"=>"foo"},
            "instance"=>{
              "id"=>257843, "name"=>nil,
              "role"=>"app", "status"=>"starting"
            },
            "status"=>"accepted"}'
      )
    end

    after :all do
      @env = nil # clean up
    end

    it "will raise if role isn't present" do
      expect {
        @env.add_instance(name: 'foo')
      }.to raise_error EY::CloudClient::InvalidInstanceRole
      FakeWeb.should_not have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances")
    end

    it "will raise if role isn't either app or util" do
      expect {
        @env.add_instance(role: 'fake')
      }.to raise_error EY::CloudClient::InvalidInstanceRole
      FakeWeb.should_not have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances")
    end

    it "sends a POST request to the API" do
      @env.add_instance(role: "app")
      FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances")
    end

    it "returns the API's response body" do
      @env.add_instance(role: "util", name: "blah").should_not be_nil
      FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances")
    end
  end


  describe "#instance_by_id(id)" do
    before :all do
      @env = EY::CloudClient::Environment.from_hash(
        EY::CloudClient.new(token: 't'),
        {
          'name' => 'fake',
          "id" => 123,
          "instances" => [
            {
              "id" => 12345,
              "role" => "app"
            }
          ]
        })
    end

    after :all do
      @env = nil
    end

    it "returns one instance when called with a valid id" do
      @env.instance_by_id(12345).should_not be_nil
    end

    it "returns nil when called with a non-existent id" do
      @env.instance_by_id(54321).should be_nil
    end
  end
end
