RSpec.describe SolrCloud::Alias do
  before(:all) do
    cleanout!
    @server = connection
    @config_name = @server.create_configset(name: rnd_configname, confdir: test_conf_dir, force: true)
    @c = @server.create_collection(name: rnd_collname, configset: @config_name)
  end

  after(:all) do
    @c.delete!
    connection.delete_configset(@config_name)
  end

  it "has the right connection" do
    a = @server.create_alias(name: rnd_aliasname, collection_name: @c.name)
    expect(a.connection.inspect).to eq(@server.inspect)
    a.delete!
  end

  it "can create an alias" do
    a = @server.create_alias(name: rnd_aliasname, collection_name: @c.name)
    expect(@server.alias_names).to include(a.name)
    a.delete!
  end

  it "can delete an alias" do
    a = @server.create_alias(name: rnd_aliasname, collection_name: @c.name)
    a.delete!
    expect(@server.alias_names).not_to include(a.name)
  end

  it "can create and delete an alias" do
    a = @server.create_alias(name: rnd_aliasname, collection_name: @c.name)
    expect(@server.alias_names).to include(a.name)
    @server.delete_alias!(a.name)
    expect(@server.alias_names).not_to include(a.name)
  end


  it "identifies as an alias" do
    a = @server.create_alias(name: rnd_aliasname, collection_name: @c.name)
    expect(a.alias?)
    a.delete!
  end

  it "can be found as if it's a collection" do
    a = @c.alias_as(rnd_aliasname)
    expect(@server.collection_names).to include(a.name)
    a.delete!
  end

  it "can be gotten as if it's a collection" do
    a = @c.alias_as(rnd_aliasname)
    expect(@server.get_collection(a.name)).to be_instance_of(SolrCloud::Alias)
    a.delete!
  end

  it "errors if the collection doesn't exist" do
    expect { @server.create_alias(name: rnd_aliasname, collection_name: "DOESNOTEXIST") }.to raise_error(SolrCloud::NoSuchCollectionError)
  end

  it "errors if you try to crate an alias that already exists without force: true" do
    a = @server.create_alias(name: rnd_aliasname, collection_name: @c.name)
    expect(@server.alias_names).to include(a.name)
    expect { @server.create_alias(name: a.name, collection_name: @c.name) }.to raise_error(SolrCloud::WontOverwriteError)
    expect(@server.create_alias(name: a.name, collection_name: @c.name, force: true).name).to eq(a.name)
    a.delete!
  end

  it "throws an error if you try to create it with an illegal name" do
    expect {
      @server.create_alias(name: "abc!", collection_name: @c.name)
    }.to raise_error(SolrCloud::IllegalNameError)
  end

  it "can find its collection" do
    a = @server.create_alias(name: rnd_aliasname, collection_name: @c.name)
    expect(a.collection.name).to eq(@c.name)
    a.delete!
  end

  it "returns nil if you try to get a non-existent alias" do
    expect(@server.get_alias("NOSUCHALIAS")).to be_nil
  end

  it "can reset its collection with a collection object" do
    c2 = @server.create_collection(name: rnd_collname, configset: @config_name)
    a = @server.create_alias(name: rnd_aliasname, collection_name: @c.name)
    expect(a.collection.name).to eq(@c.name)
    a.switch_collection_to(c2)
    expect(a.collection.name).to eq(c2.name)
    a.delete!
    c2.delete!
  end

end
