require 'spec_helper'

describe EY::CloudClient do
  it "holds an api token" do
    expect(EY::CloudClient.new(:token => 'asdf').connection.token).to eq("asdf")
  end

  it "uses production EY Cloud by default" do
    stub_request(:post, "https://cloud.engineyard.com/api/v2/authenticate").to_return(body: %|{"api_token": "cloudtoken"}|, headers: { content_type: 'application/json' })
    client = EY::CloudClient.new
    client.authenticate!("a@b.com", "foo")
    expect(client.connection.token).to eq("cloudtoken")
  end

  it "uses a custom endpoint to make requests" do
    stub_request(:post, "http://fake.local/api/v2/authenticate").to_return(body: %|{"api_token": "fake.localtoken"}|, headers: { content_type: 'application/json' })
    client = EY::CloudClient.new(:endpoint => "http://fake.local/")
    client.authenticate!("a@b.com", "foo")
    expect(client.connection.token).to eq("fake.localtoken")
  end

  it "raises on an invalid endpoint" do
    expect { EY::CloudClient.new(:endpoint => "non/absolute") }.to raise_error(EY::CloudClient::BadEndpointError)
  end

  it "raises InvalidCredentials when the credentials are invalid" do
    stub_request(:post, "https://cloud.engineyard.com/api/v2/authenticate").to_return(status: 401, headers: { content_type: 'application/json' })

    expect {
      EY::CloudClient.new.authenticate!("a@b.com", "foo")
    }.to raise_error(EY::CloudClient::InvalidCredentials)
  end

  it "raises RequestFailed with a friendly error when cloud is under maintenance" do
    stub_request(:post, "https://cloud.engineyard.com/api/v2/authenticate").to_return(status: 502, headers: { content_type: 'text/html' })

    expect {
      EY::CloudClient.new.authenticate!("a@b.com", "foo")
    }.to raise_error(EY::CloudClient::RequestFailed, /API is temporarily unavailable/)
  end

  it "raises RequestFailed with a friendly error when the response contains a message in json" do
    stub_request(:post, "https://cloud.engineyard.com/api/v2/authenticate").to_return(status: 409, body: %|{"message":"Important information regarding your failure"}|, headers: { content_type: 'application/json' })

    expect {
      EY::CloudClient.new.authenticate!("a@b.com", "foo")
    }.to raise_error(EY::CloudClient::RequestFailed, /Error: Important information regarding your failure/)
  end

  it "raises RequestFailed with a semi-useful error message when the body is empty" do
    stub_request(:post, "https://cloud.engineyard.com/api/v2/authenticate").to_return(status: 409, body: "", headers: { content_type: 'text/plain' })

    expect {
      EY::CloudClient.new.authenticate!("a@b.com", "foo")
    }.to raise_error(EY::CloudClient::RequestFailed, /Error: 409 Conflict/)
  end

  it "raises RequestFailed with the response body when the content type is not json" do
    stub_request(:post, "https://cloud.engineyard.com/api/v2/authenticate").to_return(status: 409, body: "What a useful error message!", headers: { content_type: 'text/plain' })

    expect {
      EY::CloudClient.new.authenticate!("a@b.com", "foo")
    }.to raise_error(EY::CloudClient::RequestFailed, /Error: 409 Conflict What a useful error message!/)
  end
end
