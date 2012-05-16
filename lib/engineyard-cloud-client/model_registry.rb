module EY
  class CloudClient
    class ModelRegistry
      def initialize
        @registry = Hash.new { |h,k| h[k] = {} }
      end

      def find(klass, id)
        if id
          @registry[klass][id]
        end
      end

      def set(klass, obj)
        if obj.respond_to?(:id) && id = obj.id
          @registry[klass][id] = obj
        end
      end
    end
  end
end
