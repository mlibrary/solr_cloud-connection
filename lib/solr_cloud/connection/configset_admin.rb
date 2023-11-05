# frozen_string_literal: true

require "zip"

module SolrCloud
  class Connection
    module ConfigsetAdmin

      # Get a list of the already-defined configSets
      # @return [Array<String>] possibly empty list of configSets
      def configsets
        get("api/cluster/configs").body["configSets"]
      end

      alias_method :configurations, :configsets

      # Check to see if a configset is defined
      # @param name [String] Name of the configSet
      # @return [Boolean] Whether a configset with that name exists
      def configset?(name)
        configsets.include? name.to_s
      end

      # Given the path to a solr configuration "conf" directory (i.e., the one with
      # solrconfig.xml in it), zip it up and send it to solr as a new configset.
      # @param name [String] Name to give the new configset
      # @param confdir [String, Pathname] Path to the solr configuration "conf" directory
      # @param force [Boolean] Whether or not to overwrite an existing configset if there is one
      # @param version [String] A "version" which will be appended to the name if given. Useful for
      # testing and cronjobs.
      # @raise [WontOverwriteError] if the configset already exists and "force" is false
      # @return [String] the name of the configset created
      def create_configset(name:, confdir:, force: false, version: "")
        config_set_name = name + version.to_s
        if configset?(config_set_name) && force == false
          raise WontOverwriteError.new("Won't replace configset #{config_set_name} unless 'force: true' passed ")
        end
        zfile = "#{Dir.tmpdir}/solr_add_configset_#{name}_#{Time.now.hash}.zip"
        z = ZipFileGenerator.new(confdir, zfile)
        z.write
        resp = self.put("api/cluster/configs/#{config_set_name}") do |req|
          req.body = File.binread(zfile)
        end
        # TODO: Error check in here somewhere
        FileUtils.rm(zfile, force: true)
        config_set_name
      end

      # Remove the configuration set with the given name. No-op if the
      # configset doesn't actually exist. Use #configset? manually if you need to raise on does-not-exist
      # @param [String,Symbol] name The name of the configuration set
      # @raise [InUseError] if the configset can't be deleted because it's in use by a live collection
      # @return [Connection] self
      def delete_configset(name)
        if configset? name
          delete("api/cluster/configs/#{name}")
        end
        self
      rescue Faraday::BadRequestError => e
        msg = e.response[:body]["error"]["msg"]
        if msg.match? /not delete ConfigSet/
          raise ConfigSetInUseError.new msg
        else
          raise e
        end
      end


      # Pulled from the examples for rubyzip. No idea why it's not just a part
      # of the normal interface, but I guess I'm not one to judge.
      class ZipFileGenerator
        # Initialize with the directory to zip and the location of the output archive.
        def initialize(input_dir, output_file)
          @input_dir = input_dir
          @output_file = output_file
        end

        # Zip the input directory.
        def write
          entries = Dir.entries(@input_dir) - %w[. ..]
          ::Zip::File.open(@output_file, create: true) do |zipfile|
            write_entries entries, '', zipfile
          end
        end

        private

        # A helper method to make the recursion work.
        def write_entries(entries, path, zipfile)
          entries.each do |e|
            zipfile_path = path == '' ? e : File.join(path, e)
            disk_file_path = File.join(@input_dir, zipfile_path)

            if File.directory? disk_file_path
              recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
            else
              put_into_archive(disk_file_path, zipfile, zipfile_path)
            end
          end
        end

        def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
          zipfile.mkdir zipfile_path
          subdir = Dir.entries(disk_file_path) - %w[. ..]
          write_entries subdir, zipfile_path, zipfile
        end

        def put_into_archive(disk_file_path, zipfile, zipfile_path)
          zipfile.add(zipfile_path, disk_file_path)
        end
      end
    end
  end
end
