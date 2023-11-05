# frozen_string_literal: true

require "solr_cloud/connection"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


def connection
 SolrCloud::Connection.new(url: ENV["SOLR_URL"], user: ENV["SOLR_USER"], password: ENV["SOLR_PASSWORD"])
end

def test_conf_dir
  "spec/data/simple_configuration/conf"
end