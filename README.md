# SolrCloud::Connection

Do basic administrative tasks on a running Solr cloud instance, including:

* list, create, and delete configsets, collections, and aliases
* get basic version information for the running solr
* check on the health of individual collections
* treat an alias (mostly) as a collection, just as you'd expect
* TODO automatically generate methods to talk to defined requestHandlers
* TODO collect and deal with search results in a sane way

## Caveats

* At this point the API is unstable, and it doesn't do any actual, you know, searching.
* Due to there not being any sense of an atomic action when administering solr, this gem does
  _no caching_. This means the individual actions can involve several round-trips to connect. On the flip
  side, if you're doing so much admin that it's a bottleneck, you're well outside this gem's target case.
* While solr aliases can point to more than one collection at a time, this gem enforces one collection
  per alias (although many alises can point to the same collection)

## Usage

### Create a connection to a running solr

A simple connection is made if you pass in basic info, or you can create a faraday connection
and pass it in yourself.

```ruby

require "solr_cloud/connection"

# You can also pass a logger or specify the Faraday adapter to use
solr = SolrCloud::connect.new(url: "http://localhost:9999", username: "user", password: "password")
#    #=> <SolrCloud::Connection http://localhost:9999/>

# or bring your own Faraday object
solr = SolrCloud::connect.new_with_faraday(faraday_connection)

```

### Configsets

Configuration sets can be created by giving a path to the `conf` directory (with
`solrconfig.xml` and the schema and such) and a name.

```ruby
connect.configset_names #=> []
cset = connect.create_configset(name: "myconfig", confdir: "/path/to/yourconfig/conf")

# Get a list of existing configsets
arr_of_configsets_objects = @connect.configsets
arr_of_names_as_strings = @connect.configset_names

# Test and see if it exists by name
connect.configset?("myconfig") #=> true

# If it already exists, you can just grab it by name

def_config = connect.configset("_default")

# It makes sure you don't overwrite when creating a new set
connect.create_configset(name: "myconfig", confdir: "/path/to/yourconfig/conf")
      #=> WontOverwriteError

# ...but you can force it
connect.create_configset(name: "myconfig", confdir: "/path/to/yourconfig/conf", force: true)

# And get rid of it
myconfig.delete!
connect.configset?("myconfig") #=> false

```

### Collections

Collections can be listed, tested for health and aliases, used to create an alias, and deleted. 

```ruby

connect.collection_names #=> []
connect.create_collection(name: "mycoll", configset: "does_not_exist") #=> SolrCloud::NoSuchConfigSetError: Configset does_not_exist doesn't exist
mycoll = connect.create_collection(name: "mycoll", configset: "_default")
mycoll.name #=> "mycoll"

# Test and see if it exists
connect.collection?("mycoll") #=> true

# Get all of them

arr_of_collection_objects = connect.collections
arr_of_names_as_strings = connect.collection_names

# or get a single one by name
coll = connect.collection("some_other_collection")

mycoll.alive? # => true
mycoll.healthy? #=> true. I'm not sure how these are different

mycoll.alias? # false. It's a collection. 

# Which configset is it based on?
mycoll.configset #=> <SolrCloud::Configset '_default' at http://localhost:9999/>

# Sniff out and create aliases
mycoll.aliases #=> [] None as of yet
myalias = mycoll.alias_as("myalias")

mycoll.aliases #=> [<SolrCloud::Alias 'myalias' (alias of 'mycoll')>]
mycoll.alias_names #=> ["myalias"]

# Collection, Alias, and Configset can all access the underlying connection object
# and call `get`, `post`, `put`, and `delete`
mycoll.collection #=> 
mycoll.collection.get("path/from/connection/url", arg1: "One", arg2: "Two")

# Try to delete the collection
mycoll.delete! #=> SolrCloud::CollectionAliasedError: Collection 'mycoll' can't be deleted; it's in use by aliases ["myalias"]
myalias.delete!

mycoll.delete!

```

### Aliases

In all the important ways, aliases can be treated like collections. Here are the exceptions.

```ruby

# You can create an alias from the collection you're aliasing
myalias = mycoll.alias_as("myalias")

# Ask the connection object if it exists, and get it
connect.alias?("myalias") #=> true
myalias = connect.alias("myalias")

# As this object if it's an alias, as opposed to a collection
myalias.alias? #=> true

# Set the collection this alias points to, removing its link from its existing collection
myalias.collection = my_other_collection #=> sets myalias to point at my_other_collection

myalias.delete!
```

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
4. docker compose run app rspec

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mlibrary/solr_cloud-connect.
