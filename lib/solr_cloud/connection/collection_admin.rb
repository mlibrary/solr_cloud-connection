# frozen_string_literal: true

module SolrCloud
  class Connection
    module CollectionAdmin

      # Get a list of existing collections
      # @return [Array<SolrCloud::Collection>] possibly empty list of collection objects
      def collections
        collection_names.map{|coll| collection(coll)}
      end

      # A list of the names of existing collections
      # @return [Array<String>] the collection names, or empty array if there are none
      def collection_names
        connection.get("api/collections").body["collections"]
      end

      # @param name [String] name of the collection to check on
      # @return [Boolean] Whether a collection with the passed name exists
      def collection?(name)
        collection_names.include? name
      end

      # Create a new collection
      # @param name [String] Name for the new collection
      # @param configset [String] name of the configset to use for this collection
      # @param version [String] A "version" which will be appended to the name, if given. Useful for
      #   testing and cronjobs.
      # @param shards [Integer]
      # @param replication_factor [Integer]
      # @raise [NoSuchConfigSetError] if the named configset doesn't exist
      # @return [Collection] the collection created
      def create_collection(name:, configset:, version: "", shards: 1, replication_factor: 1)
        name = name + version
        raise NoSuchConfigSetError.new("Configset '#{configset}' doesn't exist") unless configset?(configset)
        args = {
          :action => "CREATE",
          :name => name,
          :numShards => shards,
          :replicationFactor => replication_factor,
          "collection.configName" => configset
        }
        resp = connection.get("solr/admin/collections", args)
        collection(name)
      end

      # Remove the configuration set with the given name. No-op if the
      # collection doesn't actually exist. Use #connection? manually if you need to raise on does-not-exist
      # @param [String,Symbol] name The name of the configuration set
      # @return [Connection] self
      def delete_collection(name)
        if collection? name
          connection.get("solr/admin/collections", { action: "DELETE", name: name })
        end
        self
      rescue Faraday::BadRequestError
        raise SolrCloud::CollectionAliasedError.new("Collection '#{name}' can't be deleted; it's in use by aliases #{collection(name).alias_names}")
      end

      # Get a connection object specifically for the named collection
      # @param collection_name [String] name of the (already existing) collection
      # @return [SolrCloud::Connection::Collection] The collection connection
      # @raise [NoSuchCollectionError] if the collection doesn't exist
      def collection(collection_name)
        raise NoSuchCollectionError.new("Collection '#{collection_name}' not found") unless collection?(collection_name)
        Collection.new(name: collection_name, connection: self)
      end
    end
  end
end
