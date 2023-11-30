# frozen_string_literal: true

require "solr_cloud/connection"

module SolrCloud
  # A configset can't do much by itself, other than try to delete itself and
  # throw an error if that's an illegal operation (because a collection is
  # using it)
  class Configset
    attr_reader :name, :connection

    def initialize(name:, connection:)
      @name = name
      @connection = connection
    end

    # Delete this configset.
    # @see SolrCloud::Connection#delete_configset
    # @return The underlying connection
    def delete!
      @connection.delete_configset(name)
      @connection
    end

    def inspect
      "<#{self.class.name} '#{name}' at #{connection.url}>"
    end

    alias_method :to_s, :inspect

    def pretty_print(q)
      q.text inspect
    end
  end
end
