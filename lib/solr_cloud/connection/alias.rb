# frozen_string_literal: true

module SolrCloud
  class Connection
    class Alias < Collection

      # And alias is, shockingly, an alias
      def alias?
        true
      end

      def collection
        return @collection if @collection
        collection_name = connection.aliases.first { |x| x.first == name }.first
        Collection.new(name: collection_name, connection: connection)
      end



    end
  end
end
