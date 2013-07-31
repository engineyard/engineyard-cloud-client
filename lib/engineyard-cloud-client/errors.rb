module EY
  class CloudClient
    class Error < RuntimeError
    end

    class RequestFailed       < Error; end
    class InvalidCredentials  < RequestFailed; end
    class ResourceNotFound    < RequestFailed; end
    class InvalidInstanceRole < Error; end

    class BadEndpointError < Error
      def initialize(endpoint)
        super "#{endpoint.inspect} is not a valid endpoint URI. Endpoint must be an absolute URI."
      end
    end

    class AttributeRequiredError < Error
      def initialize(attribute_name, klass = nil)
        if klass
          super "Attribute '#{attribute_name}' of class #{klass} is required for this action."
        else
          super "Attribute '#{attribute_name}' is required for this action."
        end
      end
    end

    class NoBridgeError < Error
      def initialize(env_name)
        super "The environment '#{env_name}' does not have a master instance."
      end
    end

    class BadBridgeStatusError < Error
      def initialize(bridge_status, endpoint)
        super %|Application master's status is not "running" (green); it is "#{bridge_status}". Go to #{endpoint} to address this problem.|
      end
    end
  end
end
