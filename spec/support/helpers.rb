require 'rest_client'

module SpecHelpers
  def cloud_client(token = 'asdf')
    @cloud_client ||= EY::CloudClient.new(:token => token)
  end

  def scenario_cloud_client(scenario)
    @scenario = EY::CloudClient::Test::Scenario[scenario]
    @scenario.cloud_client
  end
end
