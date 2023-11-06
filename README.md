# SolrCloud::Connection


## Usage

```ruby
require "solr_cloud/connection"

connection = SolrCloud::Connection.new(url: "http://...", username: "user", password: "password")
# or
connection = SolrCloud::Connection.new_with_faraday(faraday_connection)

# Top-ish level admin of collections and configsets

connection.configsets #=> []
connection.configset?("myconfig") #=> false

connection.create_configset(name: "myconfig", confdir: "/path/to/yourconfig/conf")

# It makes sure you don't overwrite
connection.create_configset(name: "myconfig", confdir: "/path/to/yourconfig/conf")
      #=> WontOverwriteError
# ...but you can force it
connection.create_configset(name: "myconfig", confdir: "/path/to/yourconfig/conf", force: true)


# Collections can be grabbed by name, or created if they don't already exist
collection = if connection.collection? "mycoll"
               connection.collection "mycoll"
             else  
              connection.create_collection(name: "mycoll", configset: "myconfig")
             end

# configsets can't be deleted if they're being used
connection.delete_configset("myconfig") #=> ConfigSetInUseError

# but if there aren't any conflicts, you can call delete whether they exist or not
connection.delete_collection("nosuchcollection")


# Working with an individual collection
collection = connection.collection("mycoll") #=> Collection object for "mycoll"
collection.alive? #=> true

collection.aliases #=> []
myalias = collection.create_alias("myalias") # there's no functional difference between a collection and alias
# or
myalias = collection.alias("myalias") # if it already exists

collection.alias? #=> true
myalias.alias? #=> true
myalias.alias_of #=> [collection] -- aliases can point to multiple collections.
collection.aliased_by #=> [myalias]

myalias.delete!
colletion.delete!



# Some trivial things you can do with the collection. Chainable when no other
# return value is needed.

collection.name #=> "mycoll"
collection.count #=> 1145
collection.empty!.commit.count #=> 0
collection.configset #=> "myconfig"







```


## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add solr_cloud-connection

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install solr_cloud-connection


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mlibrary/solr_cloud-connection.
