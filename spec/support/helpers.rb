require 'realweb'
require 'rest_client'

module SpecHelpers
  class UI
    def info(*)
    end
    def debug(*)
    end
  end

  module Given
    def given(name)
      include_examples name
    end
  end

  module Fixtures
    def fixture_recipes_tgz
      File.expand_path('../fixture_recipes.tgz', __FILE__)
    end

    def link_recipes_tgz(git_dir)
      system("ln -s #{fixture_recipes_tgz} #{git_dir.join('recipes.tgz')}")
    end
  end

  def ey_api
    @api ||= EY::CloudClient.new('asdf', SpecHelpers::UI.new)
  end

  def api_scenario(scenario)
    clean_eyrc # switching scenarios, always clean up
    response = ::RestClient.get(EY.fake_awsm + '/scenario', {:params => {"scenario" => scenario}})
    raise "Finding scenario failed: #{response.inspect}" unless response.code == 200
    scenario = JSON.parse(response)['scenario']
    @scenario_email     = scenario['email']
    @scenario_password  = scenario['password']
    @scenario_api_token = scenario['api_token']
    scenario
  end

  def login_scenario(scenario_name)
    scen = api_scenario(scenario_name)
    write_eyrc('api_token' => scenario_api_token)
    scen
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
