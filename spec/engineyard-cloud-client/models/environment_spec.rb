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

      stub_request(:get, "https://cloud.engineyard.com/api/v2/environments?no_instances=true").
        to_return(body: MultiJson.dump(response), headers: { content_type: "application/json" })

      environments = EY::CloudClient::Environment.all(cloud_client)

      expect(environments.length).to eq(1)
      expect(environments.first.name).to eq("myapp_production")
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

      stub_request(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments").
        to_return(body: MultiJson.dump(response), headers: { content_type: "application/json" })

      env = EY::CloudClient::Environment.create(cloud_client, {
        "app"                   => app,
        "name"                  => 'myapp_production',
        "app_server_stack_name" => 'nginx_thin',
        "region"                => 'us-west-1'
      })
      expect(WebMock).to have_requested(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments")

      expect(env.name).to eq("myapp_production")
      expect(env.account.name).to eq("myaccount")
      expect(env.apps.to_a.first.name).to eq("myapp")
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

      stub_request(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments").
        to_return(body: MultiJson.dump(response), headers: { content_type: "application/json" })

      env = EY::CloudClient::Environment.create(cloud_client, {
        "app"                   => app,
        "name"                  => "myapp_production",
        "app_server_stack_name" => "nginx_thin",
        "region"                => "us-west-1",
        "cluster_configuration" => {
          "configuration" => "solo"
        }
      })
      expect(WebMock).to have_requested(:post, "https://cloud.engineyard.com/api/v2/apps/12345/environments")

      expect(env.name).to eq("myapp_production")
      expect(env.instances.count).to eq(1)
      expect(env.bridge.role).to eq("solo")
    end
  end

  describe "#rebuild" do
    it "hits the rebuild action in the API" do
      env = EY::CloudClient::Environment.from_hash(cloud_client, { "id" => 46534 })

      stub_request(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/update_instances").
        to_return(body: "")

      env.rebuild

      expect(WebMock).to have_requested(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/update_instances")
    end
  end

  describe "#run_custom_recipes" do
    it "hits the rebuild action in the API" do
      env = EY::CloudClient::Environment.from_hash(cloud_client, { "id" => 46534 })

      stub_request(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/run_custom_recipes").
        to_return(body: "", headers: { content_type: "application/json" })

      env.run_custom_recipes

      expect(WebMock).to have_requested(:put, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/run_custom_recipes")
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

      stub_request(:get, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/instances").
        to_return(body: MultiJson.dump({"instances" => [instance_data]}), headers: { content_type: "application/json" })

      expect(env.instances.size).to eq(1)
      expect(env.instances.first).to eq(EY::CloudClient::Instance.from_hash(cloud_client, instance_data.merge('environment' => env)))
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
      expect(env.bridge!).not_to be_nil
      expect(env.bridge!.id).to eq(44206)
    end

    it "raises an error if the bridge is in a non-running state" do
      env = make_env_with_bridge("status" => "error")
      expect {
        env.bridge!
      }.to raise_error(EY::CloudClient::BadBridgeStatusError)
    end

    it "returns the bridge if told to ignore the bridge being in a non-running state" do
      env = make_env_with_bridge("status" => "error")
      ignore_bad_bridge = true
      expect(env.bridge!(ignore_bad_bridge)).not_to be_nil
      expect(env.bridge!(ignore_bad_bridge).id).to eq(44206)
    end

    it "raises an error if the bridge has fallen down" do
      env = make_env_with_bridge(nil)
      expect {
        env.bridge!
      }.to raise_error(EY::CloudClient::NoBridgeError)
    end
  end

  describe "#shorten_name_for(app)" do
    def short(environment_name, app_name)
      env = EY::CloudClient::Environment.from_hash(cloud_client, {'name' => environment_name})
      app = EY::CloudClient::App.from_hash(cloud_client, {'name' => app_name})
      env.shorten_name_for(app)
    end

    it "turns myapp+myapp_production to production" do
      expect(short('myapp_production', 'myapp')).to eq('production')
    end

    it "turns product+production to production (leaves it alone)" do
      expect(short('production', 'product')).to eq('production')
    end

    it "leaves the environment name alone when the app name appears in the middle" do
      expect(short('hattery', 'ate')).to eq('hattery')
    end

    it "does not produce an empty string when the names are the same" do
      expect(short('dev', 'dev')).to eq('dev')
    end
  end

  describe "#remove_instance(instance)" do
    before do
      @instances_response =  [
        {
          'id' => 12345,
          'role' => 'app',
          'status' => 'stale',
        },
        {
          'id' => 54321,
          'role' => 'util',
          'public_hostname' => 'some-hostname',
          'status' => 'running',
          'amazon_id' => 'i-xxxxxxx',
          'name' => 'foo'
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

      @api = EY::CloudClient.new(:token => 't')
      @env = EY::CloudClient::Environment.from_hash(@api, {
        'name' => 'fake',
        'id' => '123',
        'instances_count' => 4,
      })

      stub_request(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances").
        to_return(body: MultiJson.dump({
          "request"  => {"provisioned_id"=>"i-xxxxxx", "role"=>"app"},
          "instance" => {"amazon_id"=>"i-xxxxxxx", "id"=>12345, "role"=>"app", "status"=>"running"},
          "status"=>"accepted"
        }), headers: { content_type: "application/json" })

      stub_request(:get, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/instances?").
        to_return(body: MultiJson.dump('instances' => @instances_response), headers: { content_type: "application/json" })
    end

    after do
      @env = nil # clean up
    end

    it "raises an error if role isn't app/util" do
      i = @env.instance_by_id(8675309)
      expect {
        @env.remove_instance(i) # db_master, should fail
      }.to raise_error EY::CloudClient::InvalidInstanceRole
      expect(WebMock).not_to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances")
    end

    it "raises an error if the instance isn't provisioned yet" do
      i = @env.instance_by_id(12345)
      expect {
        @env.remove_instance(i) # app, but not provisioned and no amazon id
      }.to raise_error EY::CloudClient::InstanceNotProvisioned
      expect(WebMock).not_to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances")
    end

    it "sends an API request when things check out" do
      i = @env.instance_by_id(55555) # known good instance as defined above
      expect {
        @env.remove_instance(i)
      }.to_not raise_error
      expect(WebMock).to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances")
    end

    it "does the same thing when Instance#remove helper method is used instead" do
      i = @env.instance_by_id(54321)
      expect {
        i.remove
      }.to_not raise_error
      expect(WebMock).to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances")
    end

    it "reloads the instances after a remove request" do
      @env.instance_by_id(55555).remove
      @instances_response.pop
      stub_request(:get, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/instances?").
        to_return(body: MultiJson.dump('instances' => @instances_response), headers: { content_type: "application/json" })
      expect(WebMock).to have_requested(:get, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/instances?")
    end

    it "removes a util instance when name is supplied" do
      i = @env.instance_by_id(54321) # util name "foo"
      expect {
        @env.remove_instance(i)
      }.to_not raise_error
      expect(WebMock).to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/remove_instances")
    end
  end

  describe "#add_instances(name: 'foo', role: 'app')" do
    before :all do
      @env = EY::CloudClient::Environment.from_hash(
        EY::CloudClient.new(:token => 't'), {'name' => 'fake', "id" => "123"} )

      # Register the API endpoint with WebMock
      stub_request(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances").
        to_return(body: '{
          "request"=>{"role"=>"app", "name"=>"foo"},
          "instance"=>{
            "id"=>257843, "name"=>nil,
            "role"=>"app", "status"=>"starting"
          },
          "status"=>"accepted"}')
    end

    after :all do
      @env = nil # clean up
    end

    it "will raise if role isn't present" do
      expect {
        @env.add_instance(:name => 'foo')
      }.to raise_error EY::CloudClient::InvalidInstanceRole
      expect(WebMock).not_to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances")
    end

    it "will raise if role isn't either app or util" do
      expect {
        @env.add_instance(:role => 'fake')
      }.to raise_error EY::CloudClient::InvalidInstanceRole
      expect(WebMock).not_to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances")
    end

    it "will raise if you specify util, but not name" do
      expect {
        @env.add_instance(:role => "util")
      }.to raise_error EY::CloudClient::InvalidInstanceName
    end

    it "will raise with a blank name for util" do
      expect {
        @env.add_instance(:role => "util", :name => " ") # a space isn't a valid name, so test that too
      }.to raise_error EY::CloudClient::InvalidInstanceName
    end

    it "sends a POST request to the API" do
      stub_request(:post, "https://cloud.engineyard.com/api/v2/environments/123/add_instances")
      @env.add_instance(:role => "app")
      expect(WebMock).to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances")
    end

    it "returns the API's response body" do
      stub_request(:post, "https://cloud.engineyard.com/api/v2/environments/123/add_instances")
      expect(@env.add_instance(:role => "util", :name => "blah")).not_to be_nil
      expect(WebMock).to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{@env.id}/add_instances")
    end
  end


  describe "#instance_by_id(id)" do
    before :all do
      @env = EY::CloudClient::Environment.from_hash(
        EY::CloudClient.new(:token => 't'),
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
      expect(@env.instance_by_id(12345)).not_to be_nil
    end

    it "returns nil when called with a non-existent id" do
      expect(@env.instance_by_id(54321)).to be_nil
    end
  end
end
