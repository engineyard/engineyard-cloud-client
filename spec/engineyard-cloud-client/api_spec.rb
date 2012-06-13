require 'spec_helper'

describe EY::CloudClient do
  it "holds an api token" do
    EY::CloudClient.new(:token => 'asdf').connection.token.should == "asdf"
  end

  it "uses production EY Cloud by default" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :body => %|{"api_token": "cloudtoken"}|, :content_type => 'application/json')
    client = EY::CloudClient.new
    client.authenticate!("a@b.com", "foo")
    client.connection.token.should == "cloudtoken"
  end

  it "uses a custom endpoint to make requests" do
    FakeWeb.register_uri(:post, "http://fake.local/api/v2/authenticate", :body => %|{"api_token": "fake.localtoken"}|, :content_type => 'application/json')
    client = EY::CloudClient.new(:endpoint => "http://fake.local/")
    client.authenticate!("a@b.com", "foo")
    client.connection.token.should == "fake.localtoken"
  end

  it "raises on an invalid endpoint" do
    lambda { EY::CloudClient.new(:endpoint => "non/absolute") }.should raise_error(EY::CloudClient::BadEndpointError)
  end

  it "raises InvalidCredentials when the credentials are invalid" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 401, :content_type => 'application/json')

    lambda {
      EY::CloudClient.new.authenticate!("a@b.com", "foo")
    }.should raise_error(EY::CloudClient::InvalidCredentials)
  end

  it "raises RequestFailed with a friendly error when cloud is under maintenance" do
    FakeWeb.register_uri(:post, "https://cloud.engineyard.com/api/v2/authenticate", :status => 502, :content_type => 'text/html')

    lambda {
      EY::CloudClient.new.authenticate!("a@b.com", "foo")
    }.should raise_error(EY::CloudClient::RequestFailed, /API is temporarily unavailable/)
  end
end
