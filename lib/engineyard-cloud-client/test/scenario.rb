require 'multi_json'
require 'engineyard-cloud-client/rest_client_ext'
require 'engineyard-cloud-client/test'
require 'engineyard-cloud-client/test/fake_awsm'

module EY::CloudClient::Test
  class Scenario
    def self.[](name)
      scenarios[name] or raise "Scenario #{name.inspect} not found in:\n\t#{scenarios.keys.join("\n\t")}"
    end

    def self.scenarios
      @scenarios ||= load_scenarios
    end

    def self.load_scenarios
      response = ::RestClient.get(EY::CloudClient::Test::FakeAwsm.uri.sub(/\/?$/,'/scenarios'))
      data = MultiJson.load(response)
      data['scenarios'].inject({}) do |hsh, scenario|
        hsh[scenario['name']] = new(scenario)
        hsh
      end
    end

    attr_reader :email, :password, :api_token

    def initialize(options)
      @name      = options['name']
      @email     = options['email']
      @password  = options['password']
      @api_token = options['api_token']
    end

    def cloud_client
      EY::CloudClient.new(:endpoint => EY::CloudClient::Test::FakeAwsm.uri, :token => @api_token)
    end

    def inspect
      "#<Test::Scenario name:#@name>"
    end
  end
end
