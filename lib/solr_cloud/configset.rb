# frozen_string_literal: true

module SolrCloud
  # This is just a placeholder, and not used, until I can figure
  # out how to tell which collections are based on which configsets
  # to report that. It won't (?) tell us which have since been
  # modified through the schema API, but still would be useful.
  class Configset < Connection

    def initialize(name:, connection:) end

  end
end
