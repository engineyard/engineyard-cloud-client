require 'engineyard-cloud-client/test'

module EY::CloudClient::Test
  class QuietUI
    def info(*)
    end

    def debug(*)
    end
  end

  class VerboseUI
    def info(name, message = nil)
      say name, message
    end

    def debug(name, message = nil)
      name    = name.inspect    unless name.nil? or name.is_a?(String)
      message = message.inspect unless message.nil? or message.is_a?(String)
      say name, message
    end

    def say(status, message = nil)
      if message
        $stdout.puts "#{status.to_s.rjust(12)}  #{message}"
      else
        $stdout.puts status
      end
    end
  end

  UI = ENV['DEBUG'] ? VerboseUI : QuietUI
end
