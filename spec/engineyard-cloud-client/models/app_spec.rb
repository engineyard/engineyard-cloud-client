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

      stub_request(:get, "https://cloud.engineyard.com/api/v2/apps?no_instances=true").
        to_return(body: MultiJson.dump(response), headers: { content_type: "application/json" })

      apps = EY::CloudClient::App.all(cloud_client)

      expect(apps.length).to eq(1)
      expect(apps.first.name).to eq("myapp")
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

      stub_request(:post, "https://cloud.engineyard.com/api/v2/accounts/1234/apps").
        to_return(body: MultiJson.dump(response), headers: { content_type: "application/json" })

      app = EY::CloudClient::App.create(cloud_client, {
        "account"        => account,
        "name"           => 'myapp',
        "repository_uri" => 'git@github.com:myaccount/myapp.git',
        "app_type_id"    => 'rails3'
      })

      expect(WebMock).to have_requested(:post, "https://cloud.engineyard.com/api/v2/accounts/1234/apps")

      expect(app.name).to eq("myapp")
      expect(app.account.name).to eq("myaccount")
      expect(app.hierarchy_name).to eq("myaccount / myapp")
    end
  end
end
