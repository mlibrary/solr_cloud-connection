# frozen_string_literal: true

module SolrCloud
  class Connection
    module AliasAdmin

      # Create an alias for the given collection name
      # @TODO allow an alias to point to more than one collection
      # @param name [String] Name of the new alias
      # @param collection_name [String] name of the collection
      # @param force [Boolean] whether to overwrite an existing alias
      # @raise [WontOverwriteError] if the alias exists and force isn't true
      # @raise [NoSuchCollectionError] if the collections isn't found
      # @return [Alias] the newly-created alias
      def create_alias(name: , collection_name:, force: false)
        raise NoSuchCollectionError unless collection?(collection_name)
        raise WontOverwriteError if alias?(name) and not force
        

      end

      # Get the aliases
      # @return [Array<Alias>] A list of aliases
      def aliases
        get("solr/admin/collections", action: "LISTALIASES").body["aliases"].to_a
      end

    end
  end

end