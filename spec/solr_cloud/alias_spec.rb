RSpec.describe SolrCloud::Alias do
  before(:all) do
    verify_test_environment!
  end

  before(:each) do |example|
    cleanout!
    @conn = connection
    @config_name = @conn.create_configset(name: rnd_configname, confdir: test_conf_dir, force: true)
    @collection = @conn.create_collection(name: rnd_collname, configset: @config_name)
  end

  it "connection can create and delete an alias" do
    a = @conn.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(@conn.aliases).to include(a.name)
    a.delete!
    expect(@conn.aliases).not_to include(a.name)
  end

  it "identifies as an alias" do
    a = @conn.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(a.alias?)
  end

  it "errors if the collection doesn't exist" do
    expect { @conn.create_alias(name: rnd_aliasname, collection_name: "DOESNOTEXIST") }.to raise_error(SolrCloud::NoSuchCollectionError)
  end

  it "errors if you try to crate an alias that already exists without force: true" do
    a = @conn.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(@conn.aliases).to include(a.name)
    expect { @conn.create_alias(name: a.name, collection_name: @collection.name) }.to raise_error(SolrCloud::WontOverwriteError)
    expect(@conn.create_alias(name: a.name, collection_name: @collection.name, force: true).name).to eq(a.name)
    a.delete!
  end

  it "can find its collection" do
    a = @conn.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(a.collection.name).to eq(@collection.name)
    a.delete!
  end

  it "errors out if you try to get a non-existent alias" do
    expect { @conn.alias("NOSUCHALIAS") }.to raise_error(SolrCloud::NoSuchAliasError)
  end

  it "can reset its collection with a collection object" do
    a = @conn.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(a.collection.name).to eq(@collection.name)
    c2 = @conn.create_collection(name: rnd_collname, configset: @config_name)
    a.collection = c2
    expect(a.collection.name).to eq(c2.name)
    a.delete!
    c2.delete!
  end

  it "can reset its collection with a collection name (string)" do
    a = @conn.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(a.collection.name).to eq(@collection.name)
    c2 = @conn.create_collection(name: rnd_collname, configset: @config_name)
    a.collection = c2.name
    expect(a.collection.name).to eq(c2.name)
  end

end
