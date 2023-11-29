# frozen_string_literal: true

RSpec.describe SolrCloud::Connection do

  before(:all) do
    verify_test_environment!
    cleanout!
    @solr = connection
    @confname = "config_tests" + Random.rand(999).to_s
    @collection_name = "collection_tests" + Random.rand(999).to_s
  end

  it "has a version number" do
    expect(SolrCloud::Connection::VERSION).not_to be nil
  end

  describe "creating" do
    describe "logger" do
      it "gets a standard logger" do
        c = SolrCloud::Connection.new(url: test_url, user: test_user, password: test_password)
        expect(c.logger.level).to eq(Logger::WARN)
      end

      it "gets a null logger on :off" do
        c = SolrCloud::Connection.new(url: test_url, logger: :off, user: test_user, password: test_password)
        expect(c.logger.level).to eq(Logger::FATAL)
      end

      it "will take a given logger" do
        c = SolrCloud::Connection.new(url: test_url, logger: Logger.new($stderr, level: Logger::DEBUG), user: test_user, password: test_password)
        expect(c.logger.level).to eq(Logger::DEBUG)
      end
    end

    it "can build from existing faraday connection" do
      f = Faraday.new(url: test_url) do |faraday|
        faraday.request :authorization, :basic, test_user, test_password
      end
      s = SolrCloud::Connection.new_from_faraday(f)
      expect(s.url).to eq(test_url)
    end

    it "will report a failure to connect" do
      expect {SolrCloud::Connection.new(url: "http://localhost:9090911") }.to raise_error(SolrCloud::ConnectionFailed)
    end

    it "will report a failure to authorize" do
      expect {SolrCloud::Connection.new(url: test_url, user: "NOBODY")}.to raise_error(SolrCloud::Unauthorized)
    end
  end

  describe "config sets" do
    it "can get list of configsets" do
      expect(@solr.configurations).to be_a(Array)
    end

    it "can create/delete a configset" do
      @solr.create_configset(name: @confname, confdir: test_conf_dir)
      expect(@solr.configset_names).to include(@confname)
      @solr.delete_configset(@confname)
      expect(@solr.configset_names).not_to include(@confname)
    end

    it "won't overwrite existing configset without force: true" do
      @solr.create_configset(name: @confname, confdir: test_conf_dir)
      expect { @solr.create_configset(name: @confname, confdir: test_conf_dir) }.to raise_error(SolrCloud::WontOverwriteError)
      @solr.delete_configset(@confname)
    end

    it "will overwrite existing configset by using force: true" do
      @solr.create_configset(name: @confname, confdir: test_conf_dir)
      expect { @solr.create_configset(name: @confname, confdir: test_conf_dir, force: true) }.not_to raise_error
      @solr.delete_configset(@confname)
    end

  end


  describe "individual collections" do
    before(:all) do
      @collection_name = "test_collection"
      @confname = "test_configuration"
      @solr = connection
      @solr.delete_collection(@collection_name)
      @solr.delete_configset(@confname)
      @solr.create_configset(name: @confname, confdir: test_conf_dir, force: true)
    end

    after(:all) do
      @solr.delete_configset(@confname)
    end

    before(:each) do
      @coll = @solr.create_collection(name: @collection_name, configset: @confname)
    end

    after(:each) do
      @solr.delete_collection(@collection_name)
    end

    it "can ping a collection to see if it's alive" do
      expect(@coll.alive?)
    end
  end
end
