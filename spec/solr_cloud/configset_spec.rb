# frozen_string_literal: true

RSpec.describe SolrCloud::Configset do

  before(:all) do
    verify_test_environment!
    cleanout!
    @solr = connection
    @configname = "config_tests" + Random.rand(999).to_s
    @collection_name = "collection_tests" + Random.rand(999).to_s
  end

  describe "config sets via the connection" do
    it "can get list of configsets" do
      expect(@solr.configurations).to be_a(Array)
    end

    it "can create/delete a configset" do
      @solr.create_configset(name: @configname, confdir: test_conf_dir)
      expect(@solr.configset_names).to include(@configname)
      @solr.delete_configset(@configname)
      expect(@solr.configset_names).not_to include(@configname)
    end

    it "throws an error if you try to create it with an illegal name" do
      expect {
        @solr.create_configset(name: "abc!", confdir: test_conf_dir)
      }.to raise_error(SolrCloud::IllegalNameError)
    end

    it "won't overwrite existing configset without force: true" do
      @solr.create_configset(name: @configname, confdir: test_conf_dir)
      expect { @solr.create_configset(name: @configname, confdir: test_conf_dir) }.to raise_error(SolrCloud::WontOverwriteError)
      @solr.delete_configset(@configname)
    end

    it "will overwrite existing configset by using force: true" do
      @solr.create_configset(name: @configname, confdir: test_conf_dir)
      expect { @solr.create_configset(name: @configname, confdir: test_conf_dir, force: true) }.not_to raise_error
      @solr.delete_configset(@configname)
    end
  end

  describe "configset object" do
    it "can delete itself" do
      cset = @solr.create_configset(name: rnd_configname, confdir: test_conf_dir)
      expect(@solr.configset_names).to include(cset.name)
      cset.delete!
      expect(@solr.configset_names).not_to include(cset.name)
    end
  end
end
