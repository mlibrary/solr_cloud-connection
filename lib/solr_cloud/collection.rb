# frozen_string_literal: true

require "solr_cloud/connection"

module SolrCloud
  # A Collection provides basic services on the collection -- checking its health,
  # creating or reporting aliases, and deleting itself.
  class Collection
    attr_reader :name, :connection

    # In general, users shouldn't use Collection.new; instead, use
    # connection.create_collection(name: "coll_name", configset: "existing_configset_name")
    #
    # @param [String] name The name of the (already existing) collection
    # @param [SolrCloud::Connection] connection Connection to the solr "root" (http://blah:8888/)
    def initialize(name:, connection:)
      # raise NoSuchCollectionError.new("No collection #{name}") unless connection.collection?(name)
      @connection = connection.dup
      @name = name
      @sp = "/solr/#{name}"
    end

    # Delete this collection. Unlike the #delete_collection call on a Connection object,
    # for this one we throw an error if the collection isn't found, since that means
    # it was deleted via some other mechanism after this object was created and should probably be investigated.
    # @return [Connection] The underlying SolrCloud::Connection
    def delete!
      raise NoSuchCollectionError unless exist?
      connection.delete_collection(name)
      connection
    end

    # Check to see if the collection is alive
    # @return [Boolean]
    def alive?
      connection.get("solr/#{name}/admin/ping").body["status"]
    rescue Faraday::ResourceNotFound
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

    # Access to the root info from the api. Mostly for internal use, but not labeled as such
    # 'cause users will almost certainly find a use for it.
    def info
      connection.get("api/collections/#{name}").body["cluster"]["collections"][name]
    end

    # Reported as healthy?
    # @return [Boolean]
    def healthy?
      info["health"] == "GREEN"
    end

    # A (possibly empty) list of aliases targeting this collection
    # @return [Array<SolrCloud::Alias>] list of aliases that point to this collection
    def aliases
      alias_map = connection.get("solr/admin/collections", action: "LISTALIASES").body["aliases"]
      alias_map.select { |a, c| c == name }.keys.map { |aname| Alias.new(name: aname, connection: connection) }
    end

    # The names of the aliases that point to this collection
    # @return [Array<String>] the alias names
    def alias_names
      aliases.map(&:name)
    end

    # Get a specific alias by name
    # @param name [String] name of the alias
    # @todo Check to make sure its an alias of this collection and report an error if not
    def alias(name)
      connection.alias(name)
    end

    # Create an alias for this collection. Always forces an overwrite unless you tell it not to
    # @param alias_name [String] name of the alias to create
    # @param force [Boolean] whether or not to overwrite an existing alias
    # @return [SolrCloud::Alias]
    def alias_as(alias_name, force: true)
      connection.create_alias(name: alias_name, collection_name: name, force: true)
    end

    alias_method :alias_to, :alias_as
    alias_method :create_alias, :alias_as

    # Send a commit (soft if unspecified)
    # @return self
    def commit(hard: false)
      if hard
        connection.get("solr/#{name}/update", commit: true)
      else
        connection.get("solr/#{name}/update", softCommit: true)
      end
      self
    end

    # What configset was this created with?
    # @return [SolrCloud::ConfigSet]
    def configset
      Configset.new(name: info["configName"], connection: connection)
    end

    def inspect
      anames = alias_names
      astring = if anames.empty?
        ""
      else
        " (aliased by #{anames.map { |x| "'#{x}'" }.join(", ")})"
      end
      "<#{self.class} '#{name}'#{astring}>"
    end

    alias_method :to_s, :inspect

    def pretty_print(q)
      q.text inspect
    end
  end
end
