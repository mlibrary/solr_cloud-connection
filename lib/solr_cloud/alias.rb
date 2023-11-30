# frozen_string_literal: true

module SolrCloud
  # An alias can mostly be just treated as a collection. It will identify itself as an alias if you
  # call #alias, and it can return and change the underlying collection it points to.

  # An alias shouldn't be created directly. Rather, get an existing one with
  # Connection#alias, or from a collection, or create one with
  # Collection#alias_as
  class Alias < Collection
    # An alias is, shockingly, an alias. Convenience to differentiate aliases from collections.
    # @see SolrCloud::Connection#alias?
    def alias?
      true
    end

    # Delete this alias
    # @return [SolrCloud::Connection]
    def delete!
      coll = collection
      connection.delete_alias(name)
      coll
    end

    # Get the collection this alias points to.
    # In real life, Solr will allow an alias to point to more than one collection. Functionality
    # for this might be added at some point
    # @return [SolrCloud::Collection]
    def collection
      connection.collection_for_alias(name)
    end

    # Redefine what collection this alias points to
    # This is equivalent to dropping/re-adding the alias, or calling connection.create_alias with `force: true`
    # @param coll [String, Collection] either the name of the collection, or a collection object itself
    # @return [Collection] the now-current collection
    def collection=(coll)
      collect_name = case coll
      when String
        coll
      when Collection
        coll.name
      else
        raise "Alias#collection= only takes a name(string) or a collection, not '#{coll}'"
      end
      raise NoSuchCollectionError unless connection.collection?(collect_name)
      connection.create_alias(name: name, collection_name: collect_name, force: true)
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
