# frozen_string_literal: true
require "pathname"
$LOAD_PATH.unshift Pathname.new(__dir__) + "lib"
require_relative "lib/solr_cloud/connection"
config_directory = "/Users/dueberb/devel/mlibrary/solr_cloud-connection/spec/data/simple_configuration/conf"
url = "http://localhost:9090"
user = "solr"
pass = "SolrRocks"


server = SolrCloud::Connection.new(url: url, user: user, password: pass) #=>


server.aliases.each {|a| a.delete!}
server.collections.each {|c| c.delete!}
server.configsets.reject {|c| c.name == "_default"}.each {|c| c.delete!}

# or bring your own Faraday object
# server2 = SolrCloud::Connection.new_with_faraday(faraday_connection)

### Get some basic info

server.version_string
server.cloud?
server.mode

### Configsets

# List the configsets
server.configsets

# Sometimes you just want the names.
server.configset_names

# Create a new configset by taking a conf directory, zipping it up,
# and sending it to solr
cset = server.create_configset(name: "horseless", confdir: config_directory)
server.configset_names

# That's a dumb name for a config set. Delete it and try again.
cset.delete!
cset = server.create_configset(name: "cars_cfg", confdir: config_directory)
server.configsets

# Can't be overwritten by accident
begin
  server.create_configset(name: "cars_cfg", confdir: config_directory)
rescue => e
end

# But you can force it
server.create_configset(name: "cars_cfg", confdir: config_directory, force: true)

cfg = server.get_configset("cars_cfg")
cfg.in_use?

#### Collections

# Now create a collection based on an already-existing configset
cars_v1 = server.create_collection(name: "cars_v1", configset: "cars_cfg")
server.collections
server.collection_names

# Check it out quick
cars_v1.alive?
cars_v1.healthy?
cars_v1.count

# Any aliases
cars_v1.aliased?
cars_v1.aliases

# Its configset
cars_v1.configset

# Commit anything that's been added
cars_v1.commit

# Solr knows its configset is in use, and won't delete it

begin
  cfg.delete!
rescue
end



##### Aliases

# We'll want to alias it so we can just use 'cars'
cars = cars_v1.alias_as("cars")
cars_v1.alias?
cars_v1.aliased?

cars_v1.has_alias?("cars")
cars_v1.alias_as("autos")
cars_v1.aliases

cars_v1.get_alias("autos").delete!
cars_v1.aliases

# There's syntactic sugar for switching out aliases
cars_v2 = server.create_collection(name: "cars_v2", configset: "cars_cfg")
cars = server.get_alias("cars")

cars.collection
cars.switch_collection_to("cars_v2")
cars.collection
cars_v1.aliases
cars_v2.aliases

# Aliases will swap from collection to collection without warning
cars_v1.alias_as("cars")

# ...unless you use the bang(!) version
begin
  cars_v2.alias_as!("cars")
rescue
end

# You can also just switch it from the alias itself.
cars.switch_collection_to("cars_v1")

# Aliases show up as "collections" so you can just use them interchangeably
server.collection_names

# They even == to each other
cars
cars == cars_v1
cars == cars_v2

# But sometimes you want to differentiate them from each other
server.only_collection_names
cars.alias?
cars_v1.alias?

cars.collection

### Ways to get access to aliases/collections/configsets

# You can grab existing collections/aliases/configsets from the server
# as well as when they're returned by a create_* statement
cv1 = server.get_collection("cars_v1")
cars = server.get_collection("cars")

# get_*! methods raise an error
typo = "cars_V1"
server.has_collection?(typo)
dne = server.get_collection(typo)

begin
  dne = server.get_collection!(typo)
rescue
end

# alias#collection returns the underlying collection.
# collection#collection returns itself. This makes it easier to
# write code without differentiating between them.

cars.collection
cars_v1.collection

# Configsets, Aliases, and Collections know how they're related

cars_v1.aliases
cars = cars_v1.get_alias("cars")
cfg = cars.configset
cfg.collections
