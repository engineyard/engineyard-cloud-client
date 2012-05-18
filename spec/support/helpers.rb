require 'rest_client'

module SpecHelpers
  def test_ui
    @test_ui ||= EY::CloudClient::Test::UI.new
  end

  def cloud_client(token = 'asdf', ui = test_ui)
    @cloud_client ||= EY::CloudClient.new(token, ui)
  end

  def scenario_cloud_client(scenario)
    @scenario = EY::CloudClient::Test::Scenario[scenario]
    @scenario.cloud_client
  end
end
