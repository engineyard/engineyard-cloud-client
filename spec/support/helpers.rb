require 'realweb'
require 'rest_client'

module SpecHelpers
  class UI
    def info(*)
    end
    def debug(*)
    end
  end

  def ey_api
    @api ||= EY::CloudClient.new('asdf', SpecHelpers::UI.new)
  end

  def api_scenario(scenario)
    response = ::RestClient.get(EY.fake_awsm + '/scenario', {:params => {"scenario" => scenario}})
    raise "Finding scenario failed: #{response.inspect}" unless response.code == 200
    scenario = JSON.parse(response)['scenario']
    @scenario_email     = scenario['email']
    @scenario_password  = scenario['password']
    @scenario_api_token = scenario['api_token']
    EY::CloudClient.new(@scenario_api_token, SpecHelpers::UI.new)
  end

  def scenario_email
    @scenario_email
  end

  def scenario_password
    @scenario_password
  end

  def scenario_api_token
    @scenario_api_token
  end
end
