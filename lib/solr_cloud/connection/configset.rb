# frozen_string_literal: true

module SolrCloud
  class Connection
    # A configset doesn't actually do much at this point -- just
    # mostly send stuff back to the connection
    class Configset < Connection

      def initialize(name:, connection:)

    end
  end
end