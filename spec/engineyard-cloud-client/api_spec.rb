require 'spec_helper'

describe EY::CloudClient do
  it "holds an api token" do
    EY::CloudClient.new('asdf', test_ui).token.should == "asdf"
  end

  it "holds a UI" do
    EY::CloudClient.new('asdf', test_ui).ui.should == test_ui
  end

  describe ".endpoint" do
    after do
      EY::CloudClient.default_endpoint!
    end

    it "defaults to production EY Cloud" do
      EY::CloudClient.endpoint.should == URI.parse('https://cloud.engineyard.com')
    end

    it "accepts a valid endpoint" do
      EY::CloudClient.endpoint = "http://fake.local/"
      EY::CloudClient.endpoint.should == URI.parse('http://fake.local')
    end

    it "uses the endpoint to make requests" do
      FakeWeb.register_uri(:post, "http://fake.local/api/v2/authenticate", :body => %|{"api_token": "fake.localtoken"}|, :content_type => 'application/json')

      EY::CloudClient.endpoint = "http://fake.local/"
      EY::CloudClient.authenticate("a@b.com", "foo", test_ui).should == "fake.localtoken"
    end

    it "raises on an invalid endpoint" do
      lambda { EY::CloudClient.endpoint = "non/absolute" }.should raise_error(EY::CloudClient::BadEndpointError)
    end
  end

  it "authenticates with valid credentials and returns the api token" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "asdf"}|, :content_type => 'application/json')

    EY::CloudClient.authenticate("a@b.com", "foo", test_ui).should == "asdf"
  end

  it "raises InvalidCredentials when the credentials are invalid" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 401, :content_type => 'application/json')

    lambda {
      EY::CloudClient.authenticate("a@b.com", "foo", test_ui)
    }.should raise_error(EY::CloudClient::InvalidCredentials)
  end

  it "raises RequestFailed with a friendly error when cloud is under maintenance" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 502, :content_type => 'text/html')

    lambda {
      EY::CloudClient.authenticate("a@b.com", "foo", test_ui)
    }.should raise_error(EY::CloudClient::RequestFailed, /API is temporarily unavailable/)
  end
end
