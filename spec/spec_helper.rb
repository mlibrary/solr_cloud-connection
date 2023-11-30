# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "solr_cloud/connection"
require "dotenv"
Dotenv.load! ".env.local"

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
  "collection_test_" + Random.rand(9999).to_s
end

def rnd_configname
  "config_test_" + Random.rand(9999).to_s
end

def rnd_aliasname
  "alias_test_" + Random.rand(9999).to_s
end

def cleanout!
  c = connection

  c.alias_names.select { |x| x.start_with?("alias_test_") }.each do |a|
    c.delete_alias(a)
  end

  c.collection_names.select { |x| x.start_with?("collection_test_") }.each do |cs|
    c.delete_collection(cs)
  end

  c.configset_names.select { |x| x.start_with?("config_test_") }.each do |cs|
    c.delete_configset(cs)
  end
end

def connection
  SolrCloud::Connection.new(url: test_url, user: test_user, password: test_password, logger: :none)
end

def test_conf_dir
  "spec/data/simple_configuration/conf"
end
