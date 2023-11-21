RSpec.describe SolrCloud::Collection do

  before(:all) do
    verify_test_environment!
  end

  describe "connection object can create/delete collections" do
    before(:each) do
      cleanout!
      @confname = rnd_configname
      @collection_name = rnd_collname
      @solr = connection
      @solr.create_configset(name: @confname, confdir: test_conf_dir, force: true)
    end


    it "can create/delete a collection" do
      @solr.create_collection(name: @collection_name, configset: @confname)
      expect(@solr.collection?(@collection_name))
      @solr.delete_collection(@collection_name)
      expect(@solr.collection?(@collection_name)).to be_falsey
    end

    it "doesn't identify as an alias" do
      coll = @solr.create_collection(name: @collection_name, configset: @confname)
      expect(coll.alias?).to be_falsey
    end

    it "throws an error if you try to create a collection with a bad configset" do
      expect {
        @solr.create_collection(name: @collection_name, configset: "INVALID")
      }.to raise_error(SolrCloud::NoSuchConfigSetError)
    end

    it "throws an error if you try to get admin for a non-existant collection" do
      expect { @solr.collection("INVALID_COLLECTION_NAME") }.to raise_error(SolrCloud::NoSuchCollectionError)
    end

    it "won't allow you to drop a configset in use" do
      @solr.create_configset(name: @confname, confdir: test_conf_dir, force: true)
      @solr.create_collection(name: @collection_name, configset: @confname)
      expect { @solr.delete_configset @confname }.to raise_error(SolrCloud::ConfigSetInUseError)
      @solr.delete_collection(@collection_name)
    end
  end

  describe "collection object itself can manipulate itself" do

    before(:each) do |example|
      cleanout!
      conn = connection
      config_name = conn.create_configset(name: rnd_configname, confdir: test_conf_dir, force: true)
      @collection = conn.create_collection(name: rnd_collname, configset: config_name )
    end

    it "can check for aliveness" do
      expect(@collection.alive?)
    end

    it "can check for health" do
      expect(@collection.healthy?)
    end

    it "has no aliases at this point" do
      expect(@collection.alias_names).to be_empty
    end

    it "can create an alias for itself" do
      a = @collection.alias_as(rnd_aliasname)
      expect(@collection.alias_names).to include(a.name)
    end

    it "doesn't error out on commit or hard commit" do
      expect(@collection.commit).to eq(@collection)
      expect(@collection.commit(hard: true)).to eq(@collection)

    end

    it "can delete itself" do
      conn = @collection.delete!
      expect(conn.collections).to be_empty
    end

  end
end
