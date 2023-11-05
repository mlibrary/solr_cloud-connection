# frozen_string_literal: true

require "solr_cloud/connection"

module SolrCloud
  class Connection
    class Collection < SimpleDelegator

      attr_reader :name, :connection

      # @param [String] name The name of the (already existing) collection
      # @param [SolrCloud::Connection] connection Connection to the solr "root" (http://blah:8888/)
      def initialize(name:, connection:)
        raise NoSuchCollectionError.new("No collection #{name}") unless connection.collection?(name)
        @connection = connection.dup
        @name = name
        super(@connection)
      end

      # Send a bunch of stuff to the connection's admin methods
      # @return [Boolean] does this collection still exist
      def exist?
        connection.collection?(name)
      end

      # Delete this collection. Unlike the #delete_collection call on a Connection object,
      # for this one we throw an error if the collection isn't found, since that means
      # it was deleted via some other mechanism and should probably be investigated.
      # @return [Connection] The underlying SolrCloud::Connection
      def delete!
        raise NoSuchCollectionError unless exist?
        connection.delete_collection(name)
        connection
      end

      def getsac(path = nil, *args, **kwargs)
        fullpath = if path.nil? or path == ""
                     "solr/admin/collections"
                   else
                     "solr/admin/collections/#{path}"
                   end
        get fullpath, *args, **kwargs
      end

      def ping?
        get("solr/c/admin/ping").body["status"]
      rescue Faraday::ResourceNotFound => e
        false
      end

      def reload

      end

    end
  end
end
