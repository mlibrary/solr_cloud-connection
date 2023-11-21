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
        @collection = collection_for_alias(name)
      end

      def collection=(collection)
        case collection
          when String
            raise NoSuchCollectionError unless collection?(collection)
            @collection = @connection.collection(collection)
          when Collection
            raise NoSuchCollectionError unless collection?(collection.name)
            @collection = Collection.new(name: collection, connection: @connection)
          else
            raise "Alias#collection= takes a name string or a Collection object"
        end
        connection.create_alias(name: name, collection_name: collection, force: true)
        @collection
      end

      # Override info to talk to the underlying collection
      def info
        collection.info
      end

      def inspect
        "<SolrCloud::Connection::Alias '#{name}' (alias of '#{collection.name}')>"
      end
      alias_method :to_s, :inspect

      def pretty_print(q)
        q.text inspect
      end

    end
  end
end
