module EY
  class CloudClient
  end
end

require 'engineyard-cloud-client/model_registry'
require 'engineyard-cloud-client/models'
require 'engineyard-cloud-client/rest_client_ext'
require 'engineyard-cloud-client/resolver_result'
require 'engineyard-cloud-client/version'
require 'engineyard-cloud-client/errors'
require 'multi_json'
require 'pp'

module EY
  class CloudClient
    attr_reader :token, :registry
    attr_accessor :output

    USER_AGENT_STRING = "EngineYardCloudClient/#{EY::CloudClient::VERSION}"

    def self.endpoint
      @endpoint
    end

    def self.endpoint=(endpoint)
      @endpoint = URI.parse(endpoint)
      unless @endpoint.absolute?
        raise BadEndpointError.new(endpoint)
      end
      @endpoint
    end

    def self.default_endpoint!
      self.endpoint = "https://cloud.engineyard.com/"
    end
    default_endpoint!

    def initialize(token, output=$stdout)
      self.token = token
      self.output = output
    end

    def ==(other)
      other.is_a?(self.class) && other.token == token
    end

    def registry
      @registry ||= ModelRegistry.new
    end

    def token=(new_token)
      unless new_token
        raise ArgumentError, "EY Cloud API token required"
      end
      @token = new_token
    end

    def request(url, opts={})
      opts[:headers] ||= {}
      opts[:headers]["X-EY-Cloud-Token"] = token
      self.class.request(url, output, opts)
    end

    def resolve_environments(constraints)
      EY::CloudClient::Environment.resolve(self, constraints)
    end

    def resolve_app_environments(constraints)
      EY::CloudClient::AppEnvironment.resolve(self, constraints)
    end

    def environments
      @environments ||= EY::CloudClient::Environment.all(self)
    end

    def apps
      @apps ||= EY::CloudClient::App.all(self)
    end

    # TODO: unhaxor
    # This should load an api endpoint that deals directly in app_deployments
    def app_environments
      @app_environments ||= apps.map { |app| app.app_environments }.flatten
    end

    def current_user
      EY::CloudClient::User.from_hash(self, request('/current_user')['user'])
    end

    def self.request(path, output = $stdout, opts={})
      url = self.endpoint + "api/v2#{path}"
      method = (opts.delete(:method) || 'get').to_s.downcase.to_sym
      params = opts.delete(:params) || {}
      headers = opts.delete(:headers) || {}
      headers["Accept"] ||= "application/json"
      headers["User-Agent"] = USER_AGENT_STRING

      begin
        output << debug_msg("Request", "#{method.to_s.upcase} #{url}")
        output << debug_msg("Headers", headers)
        output << debug_msg("Params", params)
        case method
        when :get, :delete, :head
          unless params.empty?
            url.query = RestClient::Payload::UrlEncoded.new(params).to_s
          end
          resp = RestClient.send(method, url.to_s, headers)
        else
          resp = RestClient.send(method, url.to_s, params, headers)
        end
      rescue RestClient::Unauthorized
        raise InvalidCredentials
      rescue Errno::ECONNREFUSED
        raise RequestFailed, "Could not reach the cloud API"
      rescue RestClient::ResourceNotFound
        raise ResourceNotFound, "The requested resource could not be found"
      rescue RestClient::BadGateway
        raise RequestFailed, "EY Cloud API is temporarily unavailable. Please try again soon."
      rescue RestClient::RequestFailed => e
        raise RequestFailed, "#{e.message} #{e.response}"
      rescue OpenSSL::SSL::SSLError
        raise RequestFailed, "SSL is misconfigured on your cloud"
      end

      if resp.body.empty?
        data = ''
      elsif resp.headers[:content_type] =~ /application\/json/
        begin
          data = MultiJson.load(resp.body)
          output << debug_msg("Response", data)
        rescue MultiJson::DecodeError
          output << debug_msg("Raw response", resp.body)
          raise RequestFailed, "Response was not valid JSON."
        end
      else
        data = resp.body
      end

      data
    end

    def self.authenticate(email, password, output=$stdout)
      request("/authenticate", output, { :method => "post", :params => { :email => email, :password => password }})["api_token"]
    end

    def debug_msg(*a)
      self.class.debug_msg(*a)
    end

    def self.debug_msg(name, value)
      return "" unless ENV['DEBUG']

      indent = 12
      unless String === value
        value = value.pretty_inspect.rstrip                 # remove trailing whitespace
        if value.index("\n")                                # if the inspect is multi-line
          value.gsub!(/[\r\n]./, "\n" + ' ' * (indent + 2)) # indent it
        end
      end
      "#{name.to_s.rjust(indent)}  #{value.rstrip}\n"       # just one newline
    end

  end # API
end # EY
