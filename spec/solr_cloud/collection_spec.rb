RSpec.describe SolrCloud::Collection do
  before(:all) do
    verify_test_environment!
    @configname = rnd_configname
    @server = connection
  end

  describe "via connection object" do
    before(:all) do
      cleanout!
      @server.create_configset(name: @configname, confdir: test_conf_dir, force: true)
    end

    after(:all) do
      @server.delete_configset(@configname)
    end

    before(:each) do
      @collection_name = rnd_collname
    end

    after(:each) do
      @server.get_collection(@collection_name).delete! if @server.has_collection?(@collection_name)
    end

    it "can create/delete a collection" do
      coll = @server.create_collection(name: @collection_name, configset: @configname)
      expect(@server.has_collection?(@collection_name))
      coll.delete!
      expect(@server.has_collection?(@collection_name)).to be_falsey
    end

    it "doesn't identify as an alias" do
      coll = @server.create_collection(name: @collection_name, configset: @configname)
      expect(coll.alias?).to be_falsey
    end

    it "throws an error if you try to create a collection with a bad configset" do
      expect {
        @server.create_collection(name: @collection_name, configset: "INVALID")
      }.to raise_error(SolrCloud::NoSuchConfigSetError)
    end

    it "returns nil if you try to get a non-existant collection with get_collection" do
      expect(@server.get_collection("INVALID_COLLECTION_NAME")).to be_nil
    end

    it "returns an error if you try to get a non-existant collection with get_collection!" do
      expect { @server.get_collection!("INVALID_COLLECTION_NAME") }.to raise_error(SolrCloud::NoSuchCollectionError)
    end

    it "can get its configset" do
      coll = @server.create_collection(name: @collection_name, configset: @configname)
      expect(coll.configset.name).to eq(@configname)
    end

    it "won't allow you to drop a configset in use" do
      @server.create_collection(name: @collection_name, configset: @configname)
      expect { @server.delete_configset @configname }.to raise_error(SolrCloud::ConfigSetInUseError)
    end

    it "throws an error if you try to create it with an illegal name" do
      expect {
        @server.create_collection(name: "abc!", configset: @configname)
      }.to raise_error(SolrCloud::IllegalNameError)
    end
  end

  describe "collection object" do
    before(:all) do
      cleanout!
      @configname = rnd_configname
      @server = connection
      @server.create_configset(name: @configname, confdir: test_conf_dir, force: true)
      @collection_name = rnd_collname
      @collection = @server.create_collection(name: @collection_name, configset: @configname)
    end

    after(:all) do
      @collection.delete!
      @server.delete_configset(@configname)
    end

    it "can check for aliveness" do
      x = @collection.alive?
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
      expect(@collection.get_alias(a.name).name).to eq(a.name)
      a.delete!
    end

    it "can't find an non-existent alias" do
      expect(@collection.get_alias("DOES_NOT_EXIST")).to be_nil
    end

    it "doesn't return an alias that points to a different collection" do
      other_collection = @server.create_collection(name: rnd_collname, configset: @configname)
      a = other_collection.alias_as(rnd_aliasname)
      expect(@collection.get_alias(a.name)).to be_nil
      a.delete!
      other_collection.delete!
    end

    it "doesn't error out on commit or hard commit" do
      expect(@collection.commit).to eq(@collection)
      expect(@collection.commit(hard: true)).to eq(@collection)
    end

    it "can delete itself" do
      coll = @server.create_collection(name: rnd_collname, configset: @configname)
      coll.delete!
      expect(@server.collection_names).not_to include(coll.name)
      coll.delete!
    end
  end

  describe "correctly forwards HTTP verbs" do
    before(:all) do
      @configset = connection.create_configset(name: rnd_configname, confdir: test_conf_dir, force: true)
    end

    after(:all) do
      @configset.delete!
    end

    it "uploads and counts" do
      coll = connection.create_collection(name: rnd_collname, configset: @configset.name)
      expect(coll.count).to be(0)
      coll.add({id: 1}).commit
      expect(coll.count).to be(1)
      coll.delete!
    end
  end
end
