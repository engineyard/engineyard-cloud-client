require 'engineyard-cloud-client/test'
require 'realweb'

module EY::CloudClient::Test
  module FakeAwsm
    def self.uri
      @uri ||= load_server
    end

    protected

    def self.load_server
      config_ru = File.expand_path("fake_awsm/config.ru", File.dirname(__FILE__))
      unless system("ruby -c '#{config_ru}' > /dev/null")
        raise SyntaxError, "There is a syntax error in fake_awsm/config.ru! FIX IT!"
      end
      if ENV['DEBUG']
        @server = RealWeb.start_server_in_thread(config_ru, :timeout => 10, :verbose => ENV['DEBUG'])
      else # fork is hell for debugging
        @server = RealWeb.start_server_in_fork(config_ru, :timeout => 10)
      end
      @server.base_uri.to_s
    end
  end
end
