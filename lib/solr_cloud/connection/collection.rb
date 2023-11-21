# frozen_string_literal: true

require "solr_cloud/connection"

module SolrCloud
  class Connection
    class Collection < SimpleDelegator

      attr_reader :name, :connection

      # @param [String] name The name of the (already existing) collection
      # @param [SolrCloud::Connection] connection Connection to the solr "root" (http://blah:8888/)
      def initialize(name:, connection:)
        # raise NoSuchCollectionError.new("No collection #{name}") unless connection.collection?(name)
        @connection = connection.dup
        @name = name
        @sp = "/solr/#{name}"
        super(@connection)
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

      # Check to see if the collection is alive
      # @return [Boolean]
      def alive?
        get("solr/#{name}/admin/ping").body["status"]
      rescue Faraday::ResourceNotFound => e
        false
      end

      alias_method :exist?, :alive?

      # Is this an alias?
      # Putting this in here breaks all sorts of isolation principles,
      # but being able to call #alias? on anything collection-like is
      # convenient
      def alias?
        false
      end

      # Access to the root info from the api
      def info
        get("api/collections/#{name}").body["cluster"]["collections"][name]
      end

      # Reported as healthy?
      def healthy?
        info["health"] == "GREEN"
      end

      # A (possibly empty) list of aliases targeting this collection
      # @return [Array<Alias>] list of aliases
      def aliases
        alias_map = get("solr/admin/collections", action: "LISTALIASES").body["aliases"]
        alias_map.select { |a, c| c == name }.keys.map{ |aname| Alias.new(name: aname, connection: connection) }
      end

      def alias_names
        aliases.map(&:name)
      end

      def alias_as(name)
        raise "TODO"
      end

      # Index a document or array of documents
      # @todo add error checking if this gets used for anything real
      def index(docs, commit: true)
        _raw_index(docs)
        self.commit if commit
        self
      end

      # Send a commit (soft if unspecified)
      # @return self
      def commit(hard: false)
        if hard
          get_update(commit: true)
        else
          get_update(nil, softCommit: true)
        end
        self
      end

      # Builder to get at various request handlers,
      # since the solr API is...inconsistent...in places.
      def get_with_prefix(prefix, path = "", *args, **kwargs)
        fullpath = if path.nil? or path == ""
                     prefix
                   else
                     "#{prefix}/#{path}"
                   end
        get fullpath, *args, **kwargs
      end

      def get_update(path = "", *args, **kwargs)
        get_with_prefix("solr/#{name}/update", path, *args, **kwargs)
      end

      def inspect
        anames = alias_names
        astring = if anames.empty?
                    ""
                  else
                    " (aliased by #{anames.map{|x| "'#{x}'"}.join(", ")})"
                  end
        "<SolrCloud::Connection::Collection '#{name}'#{astring}>"
      end
      alias_method :to_s, :inspect

      def pretty_print(q)
        q.text inspect
      end

      def _raw_index(docs)
        d = docs.kind_of?(Array) ? docs : [docs]
        post("solr/#{name}/update/json", d)
      end

    end
  end
end
