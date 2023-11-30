RSpec.describe SolrCloud::Alias do
  before(:all) do
    cleanout!
    @solr = connection
    @config_name = @solr.create_configset(name: rnd_configname, confdir: test_conf_dir, force: true)
    @collection = @solr.create_collection(name: rnd_collname, configset: @config_name)
  end

  after(:all) do
    @solr.delete_collection(@collection.name)
    @solr.delete_configset(@config_name)
  end

  it "can create and delete an alias" do
    a = @solr.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(@solr.alias_names).to include(a.name)
    a.delete!
    expect(@solr.alias_names).not_to include(a.name)
  end

  it "identifies as an alias" do
    a = @solr.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(a.alias?)
    a.delete!
  end

  it "errors if the collection doesn't exist" do
    expect { @solr.create_alias(name: rnd_aliasname, collection_name: "DOESNOTEXIST") }.to raise_error(SolrCloud::NoSuchCollectionError)
  end

  it "errors if you try to crate an alias that already exists without force: true" do
    a = @solr.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(@solr.alias_names).to include(a.name)
    expect { @solr.create_alias(name: a.name, collection_name: @collection.name) }.to raise_error(SolrCloud::WontOverwriteError)
    expect(@solr.create_alias(name: a.name, collection_name: @collection.name, force: true).name).to eq(a.name)
    a.delete!
  end

  it "can find its collection" do
    a = @solr.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(a.collection.name).to eq(@collection.name)
    a.delete!
  end

  it "errors out if you try to get a non-existent alias" do
    expect { @solr.alias("NOSUCHALIAS") }.to raise_error(SolrCloud::NoSuchAliasError)
  end

  it "can reset its collection with a collection object" do
    a = @solr.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(a.collection.name).to eq(@collection.name)
    c2 = @solr.create_collection(name: rnd_collname, configset: @config_name)
    a.collection = c2
    expect(a.collection.name).to eq(c2.name)
    a.delete!
    c2.delete!
  end

  it "can reset its collection with a collection name (string)" do
    a = @solr.create_alias(name: rnd_aliasname, collection_name: @collection.name)
    expect(a.collection.name).to eq(@collection.name)
    c2 = @solr.create_collection(name: rnd_collname, configset: @config_name)
    a.collection = c2.name
    expect(a.collection.name).to eq(c2.name)
    a.delete!
    c2.delete!
  end
end
