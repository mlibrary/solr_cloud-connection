# frozen_string_literal: true


RSpec.describe SolrCloud::Connection do
  it "has a version number" do
    expect(SolrCloud::Connection::VERSION).not_to be nil
  end

  before(:all) do
    unless %w[SOLR_URL SOLR_USER SOLR_PASSWORD].all?{|e| ENV[e] }
      raise "Must defined SOLR_URL, SOLR_USER, and SOLR_PASSWORD as env variables"
    end
    @solr = connection
    @confname = "config_tests" + Random.rand(999).to_s
    @collectionname = "collection_tests" + Random.rand(999).to_s
  end

  # TODO test create confiset won't overrite without force
  describe "config sets" do
    it "can get list of configsets" do
      expect(@solr.configurations).to be_a(Array)
    end

    it "can create/delete a configset" do
      @solr.create_configset(name: @confname, confdir: test_conf_dir)
      expect(@solr.configurations).to include(@confname)
      @solr.delete_configset(@confname)
      expect(@solr.configurations).not_to include(@confname)
    end
  end

  describe "collection create/delete" do
    before(:each) do
      @confname = "config_tests" + Random.rand(999).to_s
      @collectionname = "collection_tests" + Random.rand(999).to_s
      @solr = connection
      @solr.create_configset(name: @confname, confdir: test_conf_dir, force: true)
    end

    after(:each) do
      @solr.delete_configset(@confname)
    end

    it "can create/delete a collection" do
      @solr.create_collection(name: @collectionname, configset: @confname)
      expect(@solr.collection?(@collectionname))
      @solr.delete_collection(@collectionname)
      expect(@solr.collection?(@collectionname)).to be_falsey
    end

    it "throws an error if you try to create a collection with a bad configset" do
      expect {
        @solr.create_collection(name: @collectionname, configset: "INVALID")
      }.to raise_error(SolrCloud::NoSuchConfigSetError)
    end

    it "throws an error if you try to get admin for a non-existant collection" do
      expect { @solr.collection("INVALID_COLLECTION_NAME") }.to raise_error(SolrCloud::NoSuchCollectionError)
    end

    it "won't allow you to drop a configset in use" do
      @solr.create_configset(name:  @confname, confdir: test_conf_dir, force: true)
      @solr.create_collection(name: @collectionname, configset: @confname)
      expect { @solr.delete_configset @confname }.to raise_error(SolrCloud::ConfigSetInUseError)
      @solr.delete_collection(@collectionname)
    end
  end

  describe "individual collections" do
    before(:all) do
      @collectionname = "test_collection"
      @confname = "test_configuration"
      @solr = connection
      @solr.delete_collection(@collectionname)
      @solr.delete_configset(@confname)
      @solr.create_configset(name: @confname, confdir: test_conf_dir, force: true)
    end

    after(:all) do
      @solr.delete_configset(@confname)
    end

    before(:each) do
      @coll = @solr.create_collection(name: @collectionname, configset: @confname)
    end

    after(:each) do
      @solr.delete_collection(@collectionname)
    end

    it "can ping a collection to see if it's alive" do
      expect(@coll.alive?)
    end
  end
end
