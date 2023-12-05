# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "solr_cloud/connection"
require "dotenv"
Dotenv.load!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def verify_test_environment!
  unless %w[SOLR_URL SOLR_USER SOLR_PASSWORD].all? { |e| ENV[e] }
    raise "Must defined SOLR_URL, SOLR_USER, and SOLR_PASSWORD as env variables"
  end
end

def test_url
  ENV["SOLR_URL"].chomp("/") + "/"
end

def test_user
  ENV["SOLR_USER"]
end

def test_password
  ENV["SOLR_PASSWORD"]
end

def rnd_collname
  "rspec_collection_" + Random.rand(9999).to_s
end

def rnd_configname
  "rspec_config_" + Random.rand(9999).to_s
end

def rnd_aliasname
  "rspec_alias_" + Random.rand(9999).to_s
end

# Clean out whatever's left over from the last run of failed tests. Need to do aliases then
# collections then configsets due to possible dependencies.
def cleanout!
  connection.collections.select{|c| c.name.start_with?("rspec_alias")}.each(&:delete!)
  connection.collections.select{|c| c.name.start_with?("rspec_collection")}.each(&:delete!)
  connection.configset_names.select { |x| x.start_with?("rspec_config_") }.each do |cs|
    connection.delete_configset(cs)
  end
end

def connection
  SolrCloud::Connection.new(url: test_url, user: test_user, password: test_password, logger: :none)
end

def test_conf_dir
  "spec/data/simple_configuration/conf"
end
