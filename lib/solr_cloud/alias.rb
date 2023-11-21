# frozen_string_literal: true

module SolrCloud
  class Alias < Collection

    # And alias is, shockingly, an alias
    def alias?
      true
    end

    def delete!
      connection.delete_alias(name)
    end

    def collection
      return @collection if @collection
      @collection = connection.collection_for_alias(name)
    end

    def collection=(coll)
      case coll
        when String
          raise NoSuchCollectionError unless connection.collection?(coll)
          @collection = connection.collection(coll)
        when Collection
          raise NoSuchCollectionError unless connection.collection?(coll.name)
          @collection = Collection.new(name: coll.name, connection: @connection)
        else
          raise "Alias#collection= takes a name string or a Collection object"
      end
      connection.create_alias(name: name, collection_name: @collection.name, force: true)
      @collection
    end

    # Override info to talk to the underlying collection
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
