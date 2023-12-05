RSpec.describe SolrCloud::Collection do
  before(:all) do
    verify_test_environment!
    @configname = rnd_configname
    @solr = connection
  end

  describe "connection object can create/delete collections" do
    before(:all) do
      cleanout!
      @solr.create_configset(name: @configname, confdir: test_conf_dir, force: true)
    end

    after(:all) do
      @solr.delete_configset(@configname)
    end

    before(:each) do
      @collection_name = rnd_collname
    end

    after(:each) do
      @solr.collection(@collection_name).delete! if @solr.collection?(@collection_name)
    end

    it "can create/delete a collection" do
      coll = @solr.create_collection(name: @collection_name, configset: @configname)
      expect(@solr.collection?(@collection_name))
      coll.delete!
      expect(@solr.collection?(@collection_name)).to be_falsey
    end

    it "doesn't identify as an alias" do
      coll = @solr.create_collection(name: @collection_name, configset: @configname)
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
      @solr.create_collection(name: @collection_name, configset: @configname)
      expect { @solr.delete_configset @configname }.to raise_error(SolrCloud::ConfigSetInUseError)
    end

    it "throws an error if you try to create it with an illegal name" do
      expect {
        @solr.create_collection(name: "abc!", configset: @configname)
      }.to raise_error(SolrCloud::IllegalNameError)
    end
  end

  describe "collection object itself can manipulate itself" do
    before(:all) do
      cleanout!
      @configname = rnd_configname
      @solr = connection
      @solr.create_configset(name: @configname, confdir: test_conf_dir, force: true)
      @collection_name = rnd_collname
      @collection = @solr.create_collection(name: @collection_name, configset: @configname)
    end

    after(:all) do
      @collection.delete!
      @solr.delete_configset(@configname)
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
      a.delete!
    end

    it "can find an alias pointing to itself" do
      a = @collection.alias_as(rnd_aliasname)
      expect(@collection.alias(a.name).name).to eq(a.name)
      a.delete!
    end

    it "can't find an non-existent alias" do
      expect { @collection.alias("DOES_NOT_EXIST") }.to raise_error(SolrCloud::NoSuchAliasError)
    end

    it "doesn't return an alias that points to a different collection" do
      other_collection = @solr.create_collection(name: rnd_collname, configset: @configname)
      a = other_collection.alias_as(rnd_aliasname)
      expect { @collection.alias(a.name) }.to raise_error SolrCloud::NoSuchAliasError
      a.delete!
      other_collection.delete!
    end

    it "doesn't error out on commit or hard commit" do
      expect(@collection.commit).to eq(@collection)
      expect(@collection.commit(hard: true)).to eq(@collection)
    end

    it "can delete itself" do
      coll = @solr.create_collection(name: rnd_collname, configset: @configname)
      coll.delete!
      expect(@solr.collection_names).not_to include(coll.name)
      coll.delete!
    end
  end


  describe "correctly forwards HTTP verbs" do

    around(:all) do |ex|
      @cs = connection.create_configset(name: rnd_configname, confdir: test_conf_dir, force: true)
      ex.run
      @cs.delete!
    end

    around(:example) do |ex|
      @coll = connection.create_collection(name: rnd_collname, configset: @cs.name)
      ex.run
      @coll.delete!
    end

    it "uploads and counts" do
      expect(@coll.count).to be(0)
      @coll.add({id: 1}).commit
      expect(@coll.count).to be(1)
    end

  end
end
