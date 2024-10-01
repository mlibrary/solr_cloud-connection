# frozen_string_literal: true

RSpec.describe SolrCloud::Configset do
  before(:all) do
    verify_test_environment!
    cleanout!
    @server = connection
    @configname = "config_tests" + Random.rand(999).to_s
    @collection_name = "collection_tests" + Random.rand(999).to_s
  end

  describe "config sets via the connection" do
    it "can get list of configsets" do
      expect(@server.configsets).to be_a(Array)
    end

    it "can create/delete a configset" do
      @server.create_configset(name: @configname, confdir: test_conf_dir)
      expect(@server.configset_names).to include(@configname)
      @server.delete_configset(@configname)
      expect(@server.configset_names).not_to include(@configname)
    end

    it "throws an error if you try to create it with an illegal name" do
      expect {
        @server.create_configset(name: "abc!", confdir: test_conf_dir)
      }.to raise_error(SolrCloud::IllegalNameError)
    end

    it "won't overwrite existing configset without force: true" do
      @server.create_configset(name: @configname, confdir: test_conf_dir)
      expect { @server.create_configset(name: @configname, confdir: test_conf_dir) }.to raise_error(SolrCloud::WontOverwriteError)
      @server.delete_configset(@configname)
    end

    it "will overwrite existing configset by using force: true" do
      cset = @server.create_configset(name: @configname, confdir: test_conf_dir)
      coll = @server.create_collection(name: rnd_collname, configset: cset.name)
      expect { @server.create_configset(name: @configname, confdir: test_conf_dir, force: true) }.not_to raise_error
      coll.delete!
      cset.delete!
    end
  end

  describe "configset object" do
    before(:each) do
      @cset = @server.create_configset(name: rnd_configname, confdir: test_conf_dir)
    end

    after(:each) do
      @cset.delete! if @server.configset_names.include?(@cset.name)
    end

    it "can delete itself" do
      expect(@server.configset_names).to include(@cset.name)
      @cset.delete!
      expect(@server.configset_names).not_to include(@cset.name)
    end

    it "knows what collections use it" do
      coll = @server.create_collection(name: rnd_collname, configset: @cset.name)
      expect(@cset.used_by.map(&:name)).to include(coll.name)
      coll.delete!
    end

    it "knows if it's in use" do
      expect(@cset.in_use?).to be_falsey
      coll = @server.create_collection(name: rnd_collname, configset: @cset.name)
      expect(@cset.in_use?).to be_truthy
      coll.delete!
    end
  end
end
