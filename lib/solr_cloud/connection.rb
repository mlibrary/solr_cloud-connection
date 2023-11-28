# frozen_string_literal: true

require "faraday"
require "httpx/adapters/faraday"
require "logger"

require_relative "connection/version"
require_relative "connection/configset_admin"
require_relative "connection/collection_admin"
require_relative "connection/alias_admin"
require_relative "collection"
require_relative "alias"
require_relative "configset"
require_relative "errors"

require "forwardable"

module SolrCloud
  class Connection

    extend Forwardable

    include ConfigsetAdmin
    include CollectionAdmin
    include AliasAdmin

    attr_reader :url, :logger, :raw_connection

    def_delegators :@raw_connection, :get, :post, :delete, :put

    # Create a new connection to talk to solr
    # @param url [String] URL to the "root" of the solr installation. For a default solr setup, this will
    # just be the root url (_not_ including the `/solr`)
    # @param user [String] username for basic auth, if you're using it
    # @param password [String] password for basic auth, if you're using it
    # @param logger [#info, :off, nil] An existing logger to pass in. The symbol ":off" means
    # don't do logging. If left undefined, will create a standard ruby logger to $stdout
    # @param adapter [Symbol] The underlying http library to use within Faraday
    def initialize(url:, user: nil, password: nil, logger: nil, adapter: :httpx)
      @url = url
      @user = user
      @password = password
      @logger = case logger
                  when :off, :none
                    Logger.new(File::NULL, level: Logger::FATAL)
                  when nil
                    Logger.new($stderr, level: Logger::WARN)
                  else
                    logger
                end
      @raw_connection = create_raw_connection(url: url, adapter: adapter, user: user, password: password, logger: @logger)
      bail_if_incompatible!
      @logger.info("Connected to supported solr at #{url}")
    end

    # Pass in your own faraday connection
    # @param faraday_connection [Faraday::Connection] A pre-build faraday connection object
    def self.new_from_faraday(faraday_connection)
      c = self.allocate
      c.instance_variable_set(:@raw_connection, faraday_connection)
      c.instance_variable_set(:@url, faraday_connection.build_url.to_s)
      c
    end

    # Create a Faraday connection object to base the API client off of
    # @see #initialize
    def create_raw_connection(url:, adapter: :httpx, user: nil, password: nil, logger: nil)
      Faraday.new(request: { params_encoder: Faraday::FlatParamsEncoder }, url: URI(url)) do |faraday|
        faraday.use Faraday::Response::RaiseError
        faraday.request :url_encoded
        if user
          faraday.request :authorization, :basic, user, password
        end
        faraday.request :json
        faraday.response :json
        if logger
          faraday.response :logger, logger
        end
        faraday.adapter adapter
        faraday.headers["Content-Type"] = "application/json"
      end
    end

    # Allow accessing the raw_connection via "connection". Yes, connection.connection
    # can be confusing, but it makes the *_admin stuff easier to read.
    alias_method :connection, :raw_connection

    # Check to see if we can actually talk to the solr in question
    # raise [UnsupportedSolr] if the solr version isn't at least 8
    # raise [ConnectionFailed] if we can't connect for some reason
    def bail_if_incompatible!
      raise UnsupportedSolr.new("SolrCloud::Connection needs at least solr 8") if major_version < 8
      raise UnsupportedSolr.new("SolrCloud::Connection only works in solr cloud mode") unless cloud?
    rescue Faraday::ConnectionFailed
      raise ConnectionFailed.new("Can't connect to #{url}")
    end

    # Get basic system info from the server
    # @raise [Unauthorized] if the server gives a 401
    # @return [Hash] The response from the info call
    def system
      resp = get("/solr/admin/info/system")
      resp.body
    rescue Faraday::UnauthorizedError
      raise Unauthorized.new("Server reports failed authorization")
    end

    # @return mode [String] the mode (solrcloud or std) solr is running in
    def mode
      system["mode"]
    end

    # @return [Boolean] whether or not solr is running in cloud mode
    def cloud?
      mode == "solrcloud"
    end

    # @return [String] the major.minor.patch string of the solr version
    def version_string
      system["lucene"]["solr-spec-version"]
    end

    # Helper method to get version parts as ints
    # @return [Integer] Integerized version of the 0,1,2 portion of the version string
    def _version_part_int(index)
      version_string.split(".")[index].to_i
    end

    # @return [Integer] solr major version
    def major_version
      _version_part_int(0)
    end

    # @return [Integer] solr minor version
    def minor_version
      _version_part_int(1)
    end

    # @return [Integer] solr patch version
    def patch_version
      _version_part_int(2)
    end

    def inspect
      "<#{self.class} #{@url}>"
    end

    alias_method :to_s, :inspect

    def pretty_print(q)
      q.text inspect
    end
  end
end
