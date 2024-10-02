# SolrCloud::Connection

## Common usage

```ruby

# Connect to the server, upload a config set, make a collection based on it,
# and make an alias pointing to that collection

server = SolrCloud::Connection.new(url: url, user: user, password: pass) 
cfg = server.create_configset(name: "my_cfg", confdir: "/path/to/my/conf")
cars_v1 = server.create_collection(name: "cars_v1", configset: "my_cfg")
cars = cars_v1.alias_as("cars")

```

## Basic functionality / Roadmap

Do basic administrative tasks on a running Solr cloud instance

* [x] create (i.e., upload) a configSet when given a `conf` directory
* [x] list, create, and delete configsets, collections, and aliases
* [x] get basic version information for the running solr
* [x] check on the health of individual collections
* [x] treat an alias (mostly) as a collection
* [ ] automatically generate methods to talk to defined requestHandlers and updateHandlers
* [ ] provide a way to talk to the analyzer for testing of fieldTypes
* [ ] hook into the schema API
* [ ] allow it to work with cores, and not just solrcloud collections (which, you know bad naming then)
* [ ] figure out how to deal with managed resources
* [ ] get info from updateHandler metrics, esp. pending documents and cumulative errors
* [ ] hook into performance metrics for easy reporting and checks
* [ ] support more of the v2 API 

In almost all cases, you can treat an alias to a collection like the underlying collection. 

## A note about deleting things

Collections, aliases, and configsets all have a `#delete!` method. Keep in mind that solr 
enforces a rule that nothing in-use can be deleted. This gem will throw appropriate errors
if you try to delete a configset that's being used by a collection, or try to delete
a collections that's pointed to by an alias.

## Caveats

* At this point the API is unstable
*  Solr has no sense of an atomic action and plenty of other ways
  (e.g, the admin interface) to mess with things, so anything that doesn't
  change the data (so, basically, anything other than create or delete)
  is cached. Exceptions are obvious, e.g., `ping`
* While solr aliases can point to more than one collection at a time, 
  this gem enforces one collection
  per alias (although many aliases can point to the same collection)

## Usage

The code below covers all the basics. See the docs for full sets of parameters, which errors are
thrown, etc. 


### Create a connection to the server

```ruby
url = "http://localhost:9090/"
user = "solr"
password = "SolrRocks"
config_directory = "/path/to/myconfig/conf" # Directory 'conf' contains solrconfig.xml

require "solr_cloud/connection"

server = SolrCloud::Connection.new(url: url, user: user, password: pass) 
  #=> <SolrCloud::Connection http://localhost:9090>

  # or bring your own Faraday object
  # server2 = SolrCloud::Connection.new_with_faraday(faraday_connection)

  ### Get some basic info

server.version_string #=> "8.11.2"
server.cloud? #=> true
server.mode #=> "solrcloud"
```

### Configsets
```ruby
# List the configsets
server.configsets #=> [<SolrCloud::Configset '_default' at http://localhost:9090>]

# Sometimes you just want the names.
server.configset_names #=> ["_default"]

# Create a new configset by taking a conf directory, zipping it up,
# and sending it to solr
cset = server.create_configset(name: "horseless", confdir: config_directory)
  #=> <SolrCloud::Configset 'horseless' at http://localhost:9090>
server.configset_names #=> ["_default", "horseless"]

# That's a dumb name for a config set. Delete it and try again.
cset.delete! #=> <SolrCloud::Connection http://localhost:9090>
cset = server.create_configset(name: "cars_cfg", confdir: config_directory)
  #=> <SolrCloud::Configset 'cars_cfg' at http://localhost:9090>
server.configsets
  #=> [<SolrCloud::Configset '_default' at http://localhost:9090>,
  #    <SolrCloud::Configset 'cars_cfg' at http://localhost:9090>]

# Can't be overwritten by accident
server.create_configset(name: "cars_cfg", confdir: config_directory)
  #=> raised #<SolrCloud::WontOverwriteError: Won't replace configset cars_cfg unless 'force: true' passed >

# But you can force it
server.create_configset(name: "cars_cfg", confdir: config_directory, force: true)
  #=> <SolrCloud::Configset 'cars_cfg' at http://localhost:9090>

cfg = server.get_configset("cars_cfg") #=> <SolrCloud::Configset 'cars_cfg' at http://localhost:9090>
cfg.in_use? #=> false

```

### Collections

```ruby
# Now create a collection based on an already-existing configset
cars_v1 = server.create_collection(name: "cars_v1", configset: "cars_cfg") 
  #=> <SolrCloud::Collection 'cars_v1'>
server.collections #=> [<SolrCloud::Collection 'cars_v1'>]
server.collection_names #=> ["cars_v1"]

# Check it out quick
cars_v1.alive? #=> "OK"
cars_v1.healthy? #=> true
cars_v1.count #=> 0

# Any aliases
cars_v1.aliased? #=> false
cars_v1.aliases #=> []

# Its configset
cars_v1.configset #=> <SolrCloud::Configset 'cars_cfg' at http://localhost:9090>

# Commit anything that's been added
cars_v1.commit #=> <SolrCloud::Collection 'cars_v1'>

# Solr knows when a configset is in use, and won't delete it

cfg.delete! 
    #=> raised #<SolrCloud::ConfigSetInUseError: Can not delete ConfigSet 
    # as it is currently being used by collection [cars_v1]>

```

### Aliases

```ruby
# We'll want to alias it so we can just use 'cars'
cars = cars_v1.alias_as("cars") #=> <SolrCloud::Alias 'cars' (alias of 'cars_v1')>
cars_v1.alias? #=> false
cars_v1.aliased? #=> true

cars_v1.has_alias?("cars") #=> true
cars_v1.alias_as("autos") #=> <SolrCloud::Alias 'autos' (alias of 'cars_v1')>
cars_v1.aliases
  #=> [<SolrCloud::Alias 'cars' (alias of 'cars_v1')>, <SolrCloud::Alias 'autos' (alias of 'cars_v1')>]

cars_v1.get_alias("autos").delete! #=> <SolrCloud::Connection http://localhost:9090>
cars_v1.aliases #=> [<SolrCloud::Alias 'cars' (alias of 'cars_v1')>]

# There's syntactic sugar for switching out aliases
cars_v2 = server.create_collection(name: "cars_v2", configset: "cars_cfg") #=> <SolrCloud::Collection 'cars_v2'>
cars = server.get_alias("cars") #=> <SolrCloud::Alias 'cars' (alias of 'cars_v1')>

cars.collection #=> <SolrCloud::Collection 'cars_v1' (aliased by 'cars')>
cars.switch_collection_to("cars_v2") #=> <SolrCloud::Alias 'cars' (alias of 'cars_v2')>
cars.collection #=> <SolrCloud::Collection 'cars_v2' (aliased by 'cars')>
cars_v1.aliases #=> []
cars_v2.aliases #=> [<SolrCloud::Alias 'cars' (alias of 'cars_v2')>]

# Aliases will swap from collection to collection without warning
cars_v1.alias_as("cars") #=> <SolrCloud::Alias 'cars' (alias of 'cars_v1')>

# ...unless you use the bang(!) version
cars_v2.alias_as!("cars") #=> raised #<SolrCloud::AliasAlreadyDefinedError: Alias cars already points to cars_v1>

# You can also just switch it from the alias itself.
cars.switch_collection_to("cars_v1") #=> <SolrCloud::Alias 'cars' (alias of 'cars_v1')>

# Aliases show up as "collections" so you can just use them interchangeably
server.collection_names #=> ["cars_v1", "cars_v2", "cars"]

# They even == to each other
cars #=> <SolrCloud::Alias 'cars' (alias of 'cars_v1')>
cars == cars_v1 #=> true
cars == cars_v2 #=> false

# But sometimes you want to differentiate them from each other
server.only_collection_names #=> ["cars_v1", "cars_v2"]
cars.alias? #=> true
cars_v1.alias? #=> false

cars.collection #=> <SolrCloud::Collection 'cars_v1' (aliased by 'cars')>

```

### Accessing objects from other objects

```ruby
# You can grab existing collections/aliases/configsets from the server
# as well as when they're returned by a create_* statement
cv1 = server.get_collection("cars_v1") #=> <SolrCloud::Collection 'cars_v1' (aliased by 'cars')>
cars = server.get_collection("cars") #=> <SolrCloud::Alias 'cars' (alias of 'cars_v1')>

# get_* methods might return nil
typo = "cars_V1" #=> "cars_V1"
server.has_collection?(typo) #=> false
dne = server.get_collection(typo) #=> nil

# get_*! methods will throw an error
dne = server.get_collection!(typo) #=> raised #<SolrCloud::NoSuchCollectionError: Collection 'cars_V1' not found>

# alias#collection returns the underlying collection.
# collection#collection returns itself. This makes it easier to
# write code without differentiating between them.

cars.collection #=> <SolrCloud::Collection 'cars_v1' (aliased by 'cars')>
cars_v1.collection #=> <SolrCloud::Collection 'cars_v1' (aliased by 'cars')>

# Configsets, Aliases, and Collections know how they're related

cars_v1.aliases #=> [<SolrCloud::Alias 'cars' (alias of 'cars_v1')>]
cars = cars_v1.get_alias("cars") #=> <SolrCloud::Alias 'cars' (alias of 'cars_v1')>
cfg = cars.configset #=> <SolrCloud::Configset 'cars_cfg' at http://localhost:9090>
cfg.collections #=> [<SolrCloud::Collection 'cars_v1' (aliased by 'cars')>, <SolrCloud::Collection 'cars_v2'>]


```

## Documentation

Run `bundle exec rake docs` to generate the documentation in `docs/`

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add solr_cloud-connection

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install solr_cloud-connection

## Testing

This repository is set up to run tests under docker.

1. docker compose build
2. docker compose run app bundle install
3. docker compose up
4. docker compose run app bundle exec rspec

## Contributing

Bugs, functionality suggestions, API suggestions, feature requests, etc. all welcome
on GitHub at https://github.com/mlibrary/solr_cloud-connection.
