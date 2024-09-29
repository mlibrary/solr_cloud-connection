# frozen_string_literal: true

require_relative "lib/solr_cloud/connection/version"

Gem::Specification.new do |spec|
  spec.name = "solr_cloud-connection"
  spec.version = SolrCloud::Connection::VERSION
  spec.authors = ["Bill Dueber"]
  spec.email = ["bill@dueber.com"]

  spec.summary = "Do basic administrative operations on a solr cloud instance and collections within"
  spec.homepage = "https://github.com/mlibrary/solr_cloud-connection"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage.chomp("/") + "/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  

  spec.add_dependency "faraday", "~>2.0"
  spec.add_dependency "httpx", "~>1.0"
  spec.add_dependency "rubyzip", "~>2.0"
  spec.add_dependency "memery"

  # spec.add_development_dependency "pry"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", ">=1.35.0", "~>1.0"
  spec.add_development_dependency "simplecov", ">=0.22.0", "~>0.0"
  spec.add_development_dependency "yard", ">=0.9.0", "~>0.9.0"

  spec.add_development_dependency "dotenv", "~>3.0"
end
