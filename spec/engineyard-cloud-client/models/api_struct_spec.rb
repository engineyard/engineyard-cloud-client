require 'spec_helper'

describe EY::CloudClient::ApiStruct do
  class Foo < EY::CloudClient::ApiStruct.new(:id, :fruit, :veggie); end

  it "acts like a normal struct" do
    f = Foo.new(cloud_client, "fruit" => "banana")

    expect(f.fruit).to eq("banana")
  end

  describe "from_hash initializer" do
    it "assigns values from string keys" do
      f = Foo.from_hash(cloud_client, "fruit" => "banana")
      expect(f).to eq(Foo.new(cloud_client, "fruit" => "banana"))
    end

    it "assigns values from symbol keys" do
      f = Foo.from_hash(cloud_client, :fruit => "banana")
      expect(f).to eq(Foo.new(cloud_client, "fruit" => "banana"))
    end
  end

  describe "from_array initializer" do
    it "provides a from_array initializer" do
      f = Foo.from_array(cloud_client, [:fruit => "banana"])
      expect(f).to eq([Foo.new(cloud_client, "fruit" => "banana")])
    end

    it "handles a common-arguments hash as the second argument" do
      foos = Foo.from_array(cloud_client,
        [{:fruit => "banana"}, {:fruit => 'apple'}],
        :veggie => 'kale')
      expect(foos).to eq([
        Foo.new(cloud_client, "fruit" => "banana", "veggie" => "kale"),
        Foo.new(cloud_client, "fruit" => "apple",  "veggie" => "kale"),
      ])
    end
  end

end
