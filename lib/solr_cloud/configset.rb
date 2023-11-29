# frozen_string_literal: true

module SolrCloud
  # This is just a placeholder, and not much used, until I can figure
  # out how to tell which collections are based on which configsets
  # to report that. It won't (?) tell us which have since been
  # modified through the schema API, but still would be useful.
  class Configset

    attr_reader :name, :connection

    def initialize(name:, connection:)
      @name = name
      @connection = connection
    end

    # Delete this configset. Just calls {SolrCloud::Connection#delete_configset}
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
