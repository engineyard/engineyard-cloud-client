require 'engineyard-cloud-client/rest_client_ext'
require 'multi_json'
require 'uri'

module EY
  class CloudClient
    class Connection
      attr_reader :token, :output, :user_agent, :endpoint

      BASE_USER_AGENT = "EngineYardCloudClient/#{EY::CloudClient::VERSION}".freeze
      DEFAULT_ENDPOINT = "https://cloud.engineyard.com/".freeze

      # Initialize a new EY::CloudClient::Connection with a hash including:
      #
      # :token:      (optional) Perform authenticated requests with this token
      # :user_agent: (optional) A user agent name/version pair to add to the User-Agent header. (e.g. EngineYardCLI/2.0.0)
      # :output:     (optional) Send output to a stream other than $stdout
      # :endpoint:   (optional) An alternate Engine Yard Cloud endpoint URI
      def initialize(options={})
        @output     = options[:output] || $stdout
        @user_agent = [options[:user_agent], BASE_USER_AGENT].compact.join(' ').strip
        @endpoint   = URI.parse(options[:endpoint] || DEFAULT_ENDPOINT)
        self.token  = options[:token]

        unless @endpoint.absolute?
          raise BadEndpointError.new(@endpoint)
        end
      end

      def token=(new_token)
        @token = new_token
      end

      def debug(name, value)
        return unless ENV['DEBUG']

        indent = 12                                           # 12 because that's what Thor used.
        unless String === value
          value = value.pretty_inspect.rstrip                 # remove trailing whitespace
          if value.index("\n")                                # if the inspect is multi-line
            value.gsub!(/[\r\n]./, "\n" + ' ' * (indent + 2)) # indent it
          end
        end
        @output << "#{name.to_s.rjust(indent)}  #{value.rstrip}\n"       # just one newline
      end

      def ==(other)
        other.is_a?(self.class) && [other.token, other.user_agent, other.endpoint] == [token, user_agent, endpoint]
      end

      %w[ get head post put delete ].each do |meth|
        eval <<-RUBY, binding, __FILE__, __LINE__ + 1
          def #{meth}(path, params=nil, headers=nil, &block)
            request("#{meth}", path, params, headers, &block)
          end
        RUBY
      end

      def request(meth, path, params=nil, extra_headers=nil)
        url    = endpoint + "api/v2#{path}"
        meth   ||= 'get'
        meth   = meth.to_s.downcase.to_sym
        params ||= {}

        headers = {
          "User-Agent" => user_agent,
          "Accept"     => "application/json",
        }

        if token
          headers["X-EY-Cloud-Token"] = token
        end

        if extra_headers
          headers.merge!(extra_headers)
        end

        debug(meth.to_s.upcase, url.to_s)
        debug("Params",  params) if params
        debug("Headers", headers)

        resp = do_request(meth, url, params, headers)
        data = parse_response(resp)

        data
      end

      def authenticate!(email, password)
        response = post("/authenticate", :email => email, :password => password)
        self.token = response["api_token"]
        token
      end

      def authenticated?
        !token.nil? && !token.empty?
      end

      private

      def do_request(meth, url, params, headers)
        case meth
        when :get, :delete, :head
          if params
            url.query = RestClient::Payload::UrlEncoded.new(params).to_s
          end
          RestClient.send(meth, url.to_s, headers)
        else
          RestClient.send(meth, url.to_s, params, headers)
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

      def parse_response(resp)
        if resp.body.empty?
          ''
        elsif resp.headers[:content_type] =~ /application\/json/
          begin
            data = MultiJson.load(resp.body)
            debug("Response", data)
            data
          rescue MultiJson::DecodeError
            debug("Response", resp.body)
            raise RequestFailed, "Response was not valid JSON."
          end
        else
          resp.body
        end
      end
    end
  end
end
