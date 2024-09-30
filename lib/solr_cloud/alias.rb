# frozen_string_literal: true

module SolrCloud
  # An alias can mostly be just treated as a collection. It will identify itself as an alias if you
  # call #alias?, and it can return and change the underlying collection it points to.

  # An alias shouldn't be created directly. Rather, get an existing one with
  # Connection#alias, or from a collection, or create one with
  # Collection#alias_as
  class Alias < Collection
    # An alias is, shockingly, an alias. Convenience to differentiate aliases from collections.
    # @see SolrCloud::Connection#get_alias?
    def alias?
      true
    end

    # @overload delete!
    # Delete this alias. Will be a no-op if it doesn't exist.
    # @return [Connection] the connection
    def delete!
      connection.delete_alias!(name)
    end

    # Does this alias still exist?
    def exist?
      connection.alias_names.include?(name)
    end

    # Get the collection this alias points to.
    # In real life, Solr will allow an alias to point to more than one collection. Functionality
    # for this might be added at some point
    # @return [Collection]
    def collection
      connection.alias_map[name].collection
    end

    # Redefine what collection this alias points to
    # This is equivalent to dropping/re-adding the alias, or calling connection.create_alias with `force: true`
    # @param coll [String, Collection] either the name of the collection, or a collection object itself
    # @return [Collection] the now-current collection
    def switch_collection_to(coll)
      collect = case coll
      when String
        connection.get_collection(coll)
      when Collection
        coll
      else
        raise "Alias#switch_collection_to only takes a name(string) or a collection, not '#{coll}'"
      end
      raise NoSuchCollectionError unless connection.has_collection?(collect.name)
      # delete!
      coll.alias_as!(name)
    end

    # Get basic information on the underlying collection, so inherited methods that
    # use it (e.g., #healthy?) will work.
    # @overload info()
    def info
      collection.info
    end

    def inspect
      "<#{self.class} '#{name}' (alias of '#{collection.name}')>"
    end

    alias_method :to_s, :inspect

    def pretty_print(q)
      q.text inspect
    end
  end
end
