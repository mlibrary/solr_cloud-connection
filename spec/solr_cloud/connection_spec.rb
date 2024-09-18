# frozen_string_literal: true

RSpec.describe SolrCloud::Connection do
  before(:all) do
    verify_test_environment!
    cleanout!
    @server = connection
    @configname = "config_tests" + Random.rand(999).to_s
    @collection_name = "collection_tests" + Random.rand(999).to_s
  end

  it "has a version number" do
    expect(SolrCloud::Connection::VERSION).not_to be nil
  end

  describe "creating" do
    it "knows the uysername" do
      c = SolrCloud::Connection.new(url: test_url, user: test_user, password: test_password)
      expect(c.user).to eq(test_user)
    end

    it "knows the password" do
      c = SolrCloud::Connection.new(url: test_url, user: test_user, password: test_password)
      expect(c.password).to eq(test_password)
    end
    
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
      expect { SolrCloud::Connection.new(url: "http://localhost:9090911") }.to raise_error(SolrCloud::ConnectionFailed)
    end

    it "will report a failure to authorize" do
      expect { SolrCloud::Connection.new(url: test_url, user: "NOBODY") }.to raise_error(SolrCloud::Unauthorized)
    end
  end

  describe "utility methods" do
    it "can detect legal/illegal names for solr collections/configsets/aliases" do
      expect(@server.legal_solr_name?("abc")).to be_truthy
      expect(@server.legal_solr_name?("abc-def")).to be_truthy
      expect(@server.legal_solr_name?("abc-123")).to be_truthy
      expect(@server.legal_solr_name?("abc_123")).to be_truthy
      expect(@server.legal_solr_name?("füdgüd")).to be_falsey
      expect(@server.legal_solr_name?("abc!123")).to be_falsey
      expect(@server.legal_solr_name?("abc|123")).to be_falsey
      expect(@server.legal_solr_name?("abc.123")).to be_truthy
      expect(@server.legal_solr_name?("_abc")).to be_truthy
      expect(@server.legal_solr_name?("-abc")).to be_falsey
    end
  end
end
