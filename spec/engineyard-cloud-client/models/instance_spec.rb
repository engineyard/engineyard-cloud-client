require 'spec_helper'

describe EY::CloudClient::Instance do

  describe "#bridge?" do
    it "is true when bridge is true" do
      EY::CloudClient::Instance.from_hash(ey_api, "bridge" => true, "role" => "app").should be_bridge
    end

    it "is false when bridge is false" do
      EY::CloudClient::Instance.from_hash(ey_api, "bridge" => false, "role" => "solo").should_not be_bridge
    end

    it "is false when not set" do
      EY::CloudClient::Instance.from_hash(ey_api, "role" => "app_master").should_not be_bridge
    end
  end

  describe "#has_app_code" do
    it "is true for solos" do
      EY::CloudClient::Instance.from_hash(ey_api, "role" => "solo").should have_app_code
    end

    it "is true for app masters" do
      EY::CloudClient::Instance.from_hash(ey_api, "role" => "app_master").should have_app_code
    end

    it "is true for app slaves" do
      EY::CloudClient::Instance.from_hash(ey_api, "role" => "app").should have_app_code
    end

    it "is true for utilities" do
      EY::CloudClient::Instance.from_hash(ey_api, "role" => "util").should have_app_code
    end

    it "is false for DB masters" do
      EY::CloudClient::Instance.from_hash(ey_api, "role" => "db_master").should_not have_app_code
    end

    it "is false for DB slaves" do
      EY::CloudClient::Instance.from_hash(ey_api, "role" => "db_slave").should_not have_app_code
    end
  end
end
