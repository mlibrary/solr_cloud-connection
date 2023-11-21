# frozen_string_literal: true

module SolrCloud
  class NoSuchCollectionError < ArgumentError; end
  class NoSuchConfigSetError < ArgumentError; end
  class NoSuchAliasError < ArgumentError; end

  class WontOverwriteError < ArgumentError; end

  class ConfigSetInUseError < ArgumentError; end

  class UnsupportedSolr < RuntimeError; end

  class Unauthorized < RuntimeError; end

  class ConnectionFailed < RuntimeError; end
end
