# frozen_string_literal: true

require "zip"

module SolrCloud
  class Connection
    # Methods having to do with configsets, to be included by the connection object.
    # These are split out only to make it easier to deal with them.
    module ConfigsetAdmin
      # Given the path to a solr configuration "conf" directory (i.e., the one with
      # solrconfig.xml in it), zip it up and send it to solr as a new configset.
      #
      # The upload API endpoint differs across major Solr versions:
      #
      # - *Solr 8*: uses the V2 API (+PUT /api/cluster/configs/<name>+), which was the
      #   canonical configset path in Solr 8.
      # - *Solr 9+*: uses the V2 API (+PUT /api/configsets/<name>+).
      #   The V2 configset path moved from +/api/cluster/configs/<name>+ (Solr 8) to
      #   +/api/configsets/<name>+ (Solr 9+). The new V2 PUT defaults to overwriting an
      #   existing configset, which means in-use configsets can be replaced without
      #   deleting them first.
      #
      # Dispatches via {Connection#solr9_or_later?}; see {#upload_configset_v9} and
      # {#upload_configset_v8} for the version-specific implementations.
      #
      # @param name [String] Name to give the new configset
      # @param confdir [String, Pathname] Path to the solr configuration "conf" directory
      # @param force [Boolean] Whether or not to overwrite an existing configset if there is one
      # @raise [IllegalNameError] if +name+ is not a valid Solr identifier
      # @raise [WontOverwriteError] if the configset already exists and +force+ is false
      # @return [Configset] the configset created
      def create_configset(name:, confdir:, force: false)
        config_set_name = name
        unless legal_solr_name?(config_set_name)
          raise IllegalNameError.new("'#{config_set_name}' is not a valid solr configset name. Use only ASCII letters/numbers, dash, and underscore")
        end

        if has_configset?(config_set_name) && !force
          raise WontOverwriteError.new("Won't replace configset #{config_set_name} unless 'force: true' passed ")
        end

        zfile = "#{Dir.tmpdir}/solr_add_configset_#{name}_#{Time.now.hash}.zip"
        ZipFileGenerator.new(confdir, zfile).write

        if solr9_or_later?
          upload_configset_v9(config_set_name, zfile)
        else
          upload_configset_v8(config_set_name, zfile)
        end

        get_configset(name)
      ensure
        FileUtils.rm(zfile, force: true) if zfile
      end

      # Get a list of the already-defined configsets.
      # @return [Array<Configset>] possibly empty list of configsets
      def configsets
        configset_names.map { |cs| Configset.new(name: cs, connection: self) }
      end

      # Get the names of all defined configsets.
      #
      # The API endpoint differs across major Solr versions:
      #
      # - *Solr 8*: uses the V2 API (+GET /api/cluster/configs+).
      # - *Solr 9+*: uses the V1 API (+GET /solr/admin/configs?action=LIST+).
      #   The V2 configset path changed between Solr 8 and Solr 9; V1 is used for
      #   consistency on Solr 9 and later.
      #
      # @return [Array<String>] the names of the config sets
      def configset_names
        if solr9_or_later?
          connection.get("solr/admin/configs", action: "LIST").body["configSets"]
        else
          connection.get("api/cluster/configs").body["configSets"]
        end
      end

      # Check to see if a configset with the given name is defined.
      # @param name [String] Name of the configset
      # @return [Boolean] Whether a configset with that name exists
      def has_configset?(name)
        configset_names.include? name.to_s
      end

      # Get an existing configset by name.
      #
      # @note Does not verify that the configset actually exists; use {#has_configset?}
      #   to check first if needed.
      # @param name [String] Name of the configset
      # @return [Configset]
      def get_configset(name)
        Configset.new(name: name, connection: self)
      end

      # Remove the configuration set with the given name. No-op if the
      # configset doesn't actually exist. Test with {#has_configset?} and
      # {Configset#in_use?} manually if need be.
      #
      # In general, prefer using {Configset#delete!} instead of running everything
      # through the connection object.
      #
      # The delete API endpoint differs across major Solr versions:
      #
      # - *Solr 8*: uses the V2 API (+DELETE /api/cluster/configs/<name>+).
      # - *Solr 9+*: uses the V1 API (+GET /solr/admin/configs?action=DELETE+).
      #   The V2 configset path changed between Solr 8 and Solr 9; V1 is used for
      #   consistency on Solr 9 and later.
      #
      # @param name [String] The name of the configuration set
      # @raise [ConfigSetInUseError] if the configset can't be deleted because it's in use
      #   by a live collection
      # @return [Connection] self
      def delete_configset(name)
        if has_configset?(name)
          if solr9_or_later?
            connection.get("solr/admin/configs", action: "DELETE", name: name)
          else
            connection.delete("api/cluster/configs/#{name}")
          end
        end
        self
      rescue Faraday::BadRequestError => e
        msg = e.response[:body]["error"]["msg"]
        if msg.match?(/not delete ConfigSet/)
          raise ConfigSetInUseError.new msg
        else
          raise e
        end
      end

      # Pulled from the examples for rubyzip. No idea why it's not just a part
      # of the normal interface, but I guess I'm not one to judge.
      #
      # Code taken wholesale from https://github.com/rubyzip/rubyzip/blob/master/samples/example_recursive.rb
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
            write_entries entries, "", zipfile
          end
        end

        private

        # A helper method to make the recursion work.
        def write_entries(entries, path, zipfile)
          entries.each do |e|
            zipfile_path = (path == "") ? e : File.join(path, e)
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

      private

      # Upload a configset zip using the Solr 9+ V2 API.
      #
      # Sends a +PUT+ to +/api/configsets/<name>+ with the zip file as an
      # octet-stream body. The V2 configset upload path moved from
      # +/api/cluster/configs/<name>+ (Solr 8) to +/api/configsets/<name>+ (Solr 9+).
      # The new V2 PUT defaults to overwriting any existing configset at that name,
      # so in-use configsets can be replaced without deleting first.
      #
      # @param name [String] configset name
      # @param zipfile_path [String] filesystem path to the zip archive to upload
      # @return [void]
      def upload_configset_v9(name, zipfile_path)
        connection.put("api/configsets/#{name}") do |req|
          req.headers["Content-Type"] = "application/octet-stream"
          req.body = File.binread(zipfile_path)
        end
      end

      # Upload a configset zip using the Solr 8 V2 API.
      #
      # Sends a +PUT+ to +/api/cluster/configs/<name>+ with the zip file as an
      # octet-stream body. This was the canonical V2 configset upload path in Solr 8.
      # The path changed to +/api/configsets/<name>+ in Solr 9; use {#upload_configset_v1}
      # for Solr 9 and later.
      #
      # @param name [String] configset name
      # @param zipfile_path [String] filesystem path to the zip archive to upload
      # @return [void]
      def upload_configset_v8(name, zipfile_path)
        connection.put("api/cluster/configs/#{name}") do |req|
          req.headers["Content-Type"] = "application/octet-stream"
          req.body = File.binread(zipfile_path)
        end
      end
    end
  end
end
