require 'engineyard-cloud-client/models/api_struct'

module EY
  class CloudClient
    class Snapshot < ApiStruct.new(:amazon_id, :created_at, :size, :arch, :role, :name)
      alias id amazon_id
      
      def self.api_root(environment_id)
        "/environments/#{environment_id}/snapshots"
      end
      
      def self.all(api, environment)
        uri = api_root(environment.id)
        response = api.get(uri)
        puts response.inspect
        self.from_array(api, load_snapshots(response['snapshots']))
      end
      
      protected
      
      def self.load_snapshots(response)
        response.map do |(role, snapshots)|
          snapshots.map do |snapshot| 
            snapshot.merge(role: role[/^[^\[]+/], name: role[/\[([^\]]+)\]$/, 1])
          end
        end.flatten
      end
    end
  end
end
