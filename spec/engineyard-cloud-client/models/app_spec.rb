require 'spec_helper'

describe EY::CloudClient::App do
  describe ".all" do
    it "hits the index action in the API" do
      response = {
        "apps" => [
          {
            "environments"=>[],
            "name"=>"myapp",
            "repository_uri"=>"git@github.com:myaccount/myapp.git",
            "account"=>{"name"=>"myaccount", "id"=>1234},
            "id"=>12345
          }
        ]
      }

      FakeWeb.register_uri(:get, "https://cloud.engineyard.com/api/v2/apps?no_instances=true",
        :body => response.to_json, :content_type => "application/json")

      apps = EY::CloudClient::App.all(cloud_client)

      apps.length.should == 1
      apps.first.name.should == "myapp"
    end
  end

  describe ".create" do
    it "hits the create app action in the API" do
      account = EY::CloudClient::Account.new(cloud_client, {:id => 1234, :name => 'myaccount'})

      response = {
        "app"=>{
          "environments"=>[],
          "name"=>"myapp",
          "repository_uri"=>"git@github.com:myaccount/myapp.git",
          "account"=>{"name"=>"myaccount", "id"=>1234},
          "id"=>12345
        }
      }

      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/accounts/1234/apps",
        :body => response.to_json, :content_type => "application/json")

      app = EY::CloudClient::App.create(cloud_client, {
        "account"        => account,
        "name"           => 'myapp',
        "repository_uri" => 'git@github.com:myaccount/myapp.git',
        "app_type_id"    => 'rails3'
      })

      FakeWeb.should have_requested(:post, "https://cloud.engineyard.com/api/v2/accounts/1234/apps")

      app.name.should == "myapp"
      app.account.name.should == "myaccount"
    end
  end

  describe "#destroy" do
    it "hits the destroy action in the API" do
      pending
    end
  end
end
