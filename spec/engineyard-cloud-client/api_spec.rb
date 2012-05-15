require 'spec_helper'

describe EY::CloudClient do
  describe "endpoint" do
    after do
      EY::CloudClient.default_endpoint!
    end

    it "defaults to production EY Cloud" do
      EY::CloudClient.endpoint.should == URI.parse('https://cloud.engineyard.com')
    end

    it "loads and saves a valid endpoint" do
      EY::CloudClient.endpoint = "http://fake.local/"
      EY::CloudClient.endpoint.should == URI.parse('http://fake.local')
    end

    it "raises on an invalid endpoint" do
      lambda { EY::CloudClient.endpoint = "non/absolute" }.should raise_error(EY::CloudClient::BadEndpointError)
    end
  end

  it "gets the api token from initialize" do
    EY::CloudClient.new('asdf', SpecHelpers::UI.new).token.should == "asdf"
  end

  describe ".authenticate" do
    before(:each) do
      FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|, :content_type => 'application/json')
    end

    it "returns the token" do
      EY::CloudClient.authenticate("a@b.com", "foo", SpecHelpers::UI.new).should == "asdf"
    end
  end

  it "raises InvalidCredentials when the credentials are invalid" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 401, :content_type => 'application/json')

    lambda {
      EY::CloudClient.authenticate("a@b.com", "foo", SpecHelpers::UI.new)
    }.should raise_error(EY::CloudClient::InvalidCredentials)
  end

  it "raises RequestFailed with a friendly error when cloud is under maintenance" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 502, :content_type => 'text/html')

    lambda {
      EY::CloudClient.authenticate("a@b.com", "foo", SpecHelpers::UI.new)
    }.should raise_error(EY::CloudClient::RequestFailed, /API is temporarily unavailable/)
  end
end
