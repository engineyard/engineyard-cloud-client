require "spec_helper"
require "json"

describe EY::CloudClient::Snapshot do
  before do
    FakeWeb.allow_net_connect = true
  end

  it "lets you see an env's snapshots" do
    api = scenario_cloud_client "One App Many Envs"
    
    # in fake_awsm/scenarios.rb we put snapshots on the "giblets" environment
    env = api.environment_by_name "giblets"
    expect(env.snapshots.size).to eq(3)
  end

  it "lets you boot an instance with a snapshot of the right role" do
    # Mock output with FakeWeb and assert that the right endpoint got called.
    FakeWeb.allow_net_connect = false
    mocked_response = {
      "request" => 
      {
        "role" => "util",
        "name" => "redis"
      },
      "instance" =>
      {
        "amazon_id" => nil,
        "availability_zone" => nil,
        "bootstrapped_at" => nil,
        "chef_status" => nil,
        "error_message" => nil,
        "id" => 999999,
        "name" => "redis",
        "role" => "util",
        "size" => "medium_cpu",
        "status" => "starting",
        "public_hostname" => nil,
        "private_hostname" => nil
      },
      "status" => "accepted"
    }

    env = EY::CloudClient::Environment.from_hash(cloud_client, {"id" => 12345})
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/add_instances", :body => mocked_response.to_json)
    env.add_instance(:role => "app", :instance_size => "medium_cpu_64", :snapshot_id => "abc123")
    expect(FakeWeb).to have_requested(:post, "https://cloud.engineyard.com/api/v2/environments/#{env.id}/add_instances")    

  end
end
