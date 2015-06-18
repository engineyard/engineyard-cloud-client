require 'spec_helper'

describe EY::CloudClient::Instance do

  describe "self.valid_sizes" do
    it "returns a list of known valid sizes for instances" do
      expect(EY::CloudClient::Instance.valid_sizes).not_to be_nil
    end
  end

  describe "#bridge?" do
    it "is true when bridge is true" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "bridge" => true, "role" => "app")).to be_bridge
    end

    it "is false when bridge is false" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "bridge" => false, "role" => "solo")).not_to be_bridge
    end

    it "is false when not set" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "role" => "app_master")).not_to be_bridge
    end
  end

  describe "#has_app_code" do
    it "is true for solos" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "role" => "solo")).to have_app_code
    end

    it "is true for app masters" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "role" => "app_master")).to have_app_code
    end

    it "is true for app slaves" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "role" => "app")).to have_app_code
    end

    it "is true for utilities" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "role" => "util")).to have_app_code
    end

    it "is false for DB masters" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "role" => "db_master")).not_to have_app_code
    end

    it "is false for DB slaves" do
      expect(EY::CloudClient::Instance.from_hash(cloud_client, "role" => "db_slave")).not_to have_app_code
    end
  end
end
