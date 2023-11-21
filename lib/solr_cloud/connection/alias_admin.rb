# frozen_string_literal: true

module SolrCloud
  class Connection
    module AliasAdmin

      AliasCollectionPair = Struct.new(:alias, :collection)

      # Create an alias for the given collection name
      # @TODO allow an alias to point to more than one collection
      # @param name [String] Name of the new alias
      # @param collection_name [String] name of the collection
      # @param force [Boolean] whether to overwrite an existing alias
      # @raise [WontOverwriteError] if the alias exists and force isn't true
      # @raise [NoSuchCollectionError] if the collections isn't found
      # @return [Alias] the newly-created alias
      def create_alias(name:, collection_name:, force: false)
        raise NoSuchCollectionError.new("Can't find collection #{collection_name}") unless collection?(collection_name)
        if alias?(name) and not force
          raise WontOverwriteError.new("Alias '#{name}' already points to collection '#{self.alias(name).collection.name}'; won't overwrite without force: true")
        end
        get("solr/admin/collections", action: "CREATEALIAS", name: name, collections: collection_name)
        SolrCloud::Connection::Alias.new(name: name, connection: self)
      end

      def alias?(name)
        aliases.include? name
      end


      # Delete the alias
      # @param name [String] Name of the alias to delete
      # @return [SolrCloud::Connection]
      def delete_alias(name)
        get("solr/admin/collections", action: "DELETEALIAS", name: name)
      end

      # Get the aliases and create a map of the form
      # @return [Hash<String,Alias>] A hash mapping alias names to alias objects
      def alias_map
        get("solr/admin/collections", action: "LISTALIASES").body["aliases"].keys.each_with_object({}) do |alias_name, h|
          h[alias_name] = SolrCloud::Connection::Alias.new(name: alias_name, connection: self)
        end
      end

      # List of alias names
      # @return [Array<String>] List of aliases
      def aliases
        alias_map.keys
      end

      def alias(name)
        am = alias_map
        raise NoSuchAliasError unless am[name]
        am[name]
      end

      # Get the collection associated with an alias
      # @param name [String] alias name
      # @return [Collection] collection associated with the alias
      def collection_for_alias(name)
        collname = get("solr/admin/collections", action: "LISTALIASES").body["aliases"][name]
        Collection.new(name: collname, connection: self)
      end

    end
  end

end