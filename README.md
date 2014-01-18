Neon
====

# About
Neon is fast, minimal ruby binding for neo4j. It provides a simple api to manipulate a Neo4J database instance hosted on a server or running as an embedded instance.

# Usage
## Creating Sessions
You start a session with a Neo4J database by creating a session. You can create a session with a REST server or an Embedded instance as follows :-
### REST session

```ruby
session = Neon::Session::Rest.new(url, options)
```

* `url` defaults to http://localhost:7474
* `options` defaults to {} and takes the following keys :-

```ruby
options = {
       directory: '', # Prefix the url with this directory
          cypher: '/cypher', # Cypher path for the server
         gremlin: '/ext/GremlinPlugin/graphdb/execute_script', # Gremlin path for the server
             log: false, # Log activity or not
        log_path: 'neon.log', # File name used for the log if :log is true
         threads: 20, # Maximum number of threads to use
  authentication: nil,  # 'basic' or 'digest'
        username: nil,
        password: nil,
          parser: MultiJsonParser
}
```

You can also quickly initialize using

```ruby
session = Neon::Session::Rest.new("http://username:password@localhost:7474/mydirectory")
```

### Embedded session

```ruby
session = Neon::Session::Embedded.new(path_to_db, auto_tx)
```

* `path_to_db` is the path to the embedded database instance. You can use a symbol `:impermanent` to create an impermanent instance.
* `auto_tx` is an optional boolean parameter that is true by default and used for enabling and disabling auto transactions.

The first session created is the default session used by Neon modules. It can be accessed using the current attribute.

```ruby
Neon::Session.current
# Set another session to be current. You get a boolean on whether it was successful or not
Neon::Session.set_current another_session # Returns true or false
# You can also do this
Neon::Session.current = another_session
another_session.current? # Check if this session is the current session or not?
```

## Using Sessions
Irrespective of the underlying session, you can use a common api there onwards i.e. you only make a choice on the session type during initialization and then forget about it. All further entities are linked to this session and provide a common interface for all core graph operations.

```ruby
# Creating a session does not start it. You can start the session as follows
started? = session.start

# Close a session
closed? = session.close

# Check if a session has been started i.e. is it running?
running? = session.running?

# All instance method calls are also available on Session and are called on the current session e.g.
started? = Neon::Session.start
close? = Neon::Session.close
running? = Neon::Session.running? # and others

# Location of the database
session.location
```

### Auto Transaction support
* For REST sessions this has no consequence as auto_tx cannot be disabled. You can though run multiple statements using transactions.
* For Embedded sessions auto_tx means all graph operations will be automatically
wrapped inside a transaction which will be committed.
You can disable auto_tx in which case all operations will need to be wrapped inside a transaction by the developer.

```ruby
session.auto_tx # Defaults to true
session.auto_tx = false
Neon::Session.auto_tx = false # Disable auto transaction on the current session
```

### Node Wrapper
You can easily set a custom wrapper on your session for methods that return a node or a relationship

## Property Container
Both nodes and relationships are property containers and respond in exactly the same way to the following interface :-

```ruby
# ================================================================
# Property Container
# These methods are available on Neon::Node and Neon::Relationship
# with the same signature and behaviour.
# ================================================================

# Get a container's session
session = container.session

# Get a single key
value = container[:key] # Returns the value

# Get one or more properties
value1, value2 = container[:key1, :key2]
values = container[:key1, :key2] # Returns an array on a query of multiple propeties

# Non existing properties return nil
value = container[:invalid_key]
value, nil_value = container[:key, :invalid_key]
# The last argument can be a hash. If it is provided then you can specify a default value
# instead of nil for non exisitng keys.
value, hello_world = container[:key, :invalid_key] default: 'hello world'

# Set one or more properties
container[:key1, :key2] = value1, value2
container[:key1, :key2] = values # an array

container[:invalid_key] = value # Creates a key :invalid_key and sets it to value
container[nil] = value # Calls #to_s on every key. If multiple properties resolve to same name
# then the last value
# is used.

container[valid_key] = invalid_value # anything besides String, Symbol, Numeric, true, false or an
#array of these (all objects of the same type) is going to throw an exception InvalidValueError.
# There is an exception to this where setting a key to nil deletes it. Setting a non existing
# key to nil does nothing.

# Get all keys
keys = container.keys

# Check if a key exists
container.key?('a key') # Returns true or false on the basis of wether 'a key' exists or not
```

## Creating Nodes
Nodes are created in context to a session which determines their underlying model and data access methods. The only time you need to be think about using sessions during creation. Thereafter you can use the same api irrespective of the database.
### Create a new node

```ruby
# Create a new node
node = Neon::Node.new(attributes, label1, label2, session)
```

* `attributes` is an optional hash consisting of the key-value pairs you would like this node to be initialized with. Defaults to {}
* `labels` - You can provide a comma separated list of labels or an array of labels
* `session` - the last argument is an optional session. It defines the database where you want to create the node and defaults to the current session

All of these arguments can be used in any combination as long as the order remains the same. Skipping all of them creates an empty node in the current session. Here are all various ways to create a node :-

```ruby
# Empty node in the current session
node = Neon::Node.new

# A node with attributes in the current session and no labels
node = Neon::Node.new(name: :name, email: :email)

# A node with attributes in the given session
node = Neon::Node.new({name: :name}, another_session)

# A node with attributes and labels in the current session
node = Neon::Node.new({name: :name, sex: 'male'}, :User, :Man)
node = Neon::Node.new({name: :name, sex: 'male'}, [:User, :Man])

# A node with attributes and labels in the given session
node = Neon::Node.new({name: :name, sex: 'male'}, :User, :Man, another_session)
node = Neon::Node.new({name: :name, sex: 'male'}, [:User, :Man], another_session)

# An empty node in the given session
node = Neon::Node.new another_session

# A node with labels in the current session
node = Neon::Node.new(:User)
node = Neon::Node.new([:User])

# A node with labels in the given session
node = Neon::Node.new(:User, another_session)
node = Neon::Node.new([:User], another_session)
```

### Loading Nodes
Existing nodes can be loaded by providing an id. Non existing ids return nil.

```ruby
# Returns the load with id 5
node = Neon::Node.load(5)
same_node = Neon::Node.load(node.id)
invalid_node = Neon::Node.load(:non_existent_id)
```

## Using Nodes
Node instances have a well defined api to work with which is uniform irrespective of the underlying session.

```ruby
# Get a node's id
id = node.id

# ==============
# Node methods
# ==============

# Get all labels of a node
node.labels # => ['label', 'User', 'Programmer']

# Add one or more labels
# Labels can be anything that responds to #to_s
node.add_labels(:runner, :biker)
node.add_labels([:runner, biker])

# Remove one or more labels
node.remove_labels(:runner, :biker)
node.remove_labels([:runner, :biker])

# Check if a node has a label
node.label?(:Runner) # => returns true or false

# Create a relationship to another node
node.create_rel_to(another_node, :RELATIONSHIP_TYPE)
# If both node and another_node do not have the same database location then it throws a CrossSessionError

# Get all relationships
node.rels

# Get all relationships in a particular direction
node.rels(dir: :incoming)
node.rels(dir: :outgoing)

# Get relationships to nodes with particular labels
node.rels(labels: [:friend, :jusband])

# Get relationships of a particular type by passing a options hash with type key. 
# It can be anything that responds to #to_s
# Both directions
node.rels(type: relationship_type) # a variable that responds to #to_s. The response to #to_s is used
node.rels(type: [:relationship_type, :another_relationship_type])
# Get relationships between two nodes
node.rels(between: another_node)
# You can mix and match various options to create filters.

# Get a single relationship if it exists or nil
node.rel(dir: :incoming, type: [:RELATIONSHIP_TYPE, :ANOTHER_RELATIONSHIP_TYPE])

# Check if a node has a particular relationship
node.rel? # Any relationships?
node.rel?(dir: :incoming) or node.rel?(dir: :outgoing) # Any incoming or outgoing relationships
node.rel?(type: :RELATIONSHIP_TYPE) # => true or false
node.rel?(dir: :incoming, type: :RELATIONSHIP_TYPE) # => true or false

# Delete a node its relationships
# Raises exception if there are relationships.
node.delete # => return true or false if node was deleted

# Delete a node and it's relationships.
node.delete! # => return true or false if node was destroyed or not
```

## Relationships
### Creating Relationships
Relationships are created in context to a node as specified in the node api.
You can load relationships the same way as nodes.

### Using relationships
Relationships are property containers and therefore responds to all methods that node does under the property container section

```ruby
# Get the nodes
start_node, end_node = rel.nodes # => A 2 element array

# Get start node
rel.start

# Get end node
rel.end

# Get the other node or nil if the supplied node is not part of the relationship
rel.other(node)

# Get the type of a node. This is a object that responds to #to_s
rel.type

# Check if the relationship is of a particular type. Type can be anything that responds to #to_s
rel.type?(a_type)
```

## Transactions
Besides support for auto transactions, one can run transaction explicitly. Beginning a transaction turns off auto_tx until the end of the transaction. At the end auto_tx is restored to it's original status. You can run at most one transaction per thread.

```ruby
# Begin a transaction. If a transaction is already on then it is returned.
# Run them in a begin-rescue block since they might throw an exception
tx = session.begin_tx
begin
  # Do some graph operations
  tx.failure # mark transaction for failure. Marked by default
rescue Exception => e
  # handle execption
else
  tx.success # mark transaction for success if no exception occured
ensure
  tx.close # commit or rollback on the basis of wether tx was marked for success or failure
end

# Run a quick transaction. This fires a new transaction in a new thread.
# t is the transaction. You can call success or failure on it. Don't call close as it will throw
# an exception later. An optional session can be passed to run the transaction on. Defaults to current session.
Transaction.run(optional_session) do |t|
  # Do some graph operations.
  # If you do something here that does not pertain to the session that t belongs to then it will
  # not be a part of the transaction
end

# t is marked for success by default. This allows you run quick one method calls like
# The result of the block is returned.
result = Transaction.run { do_something_graphy }
```

## Indexes
Indexes can be set upon nodes as well as relationships using legacy indexing.
### Node Indexes
Legacy indexing on nodes can be performed as following :-
#### Fetch all node indexes

```ruby
# An array of indexes
indexes = Neon::Node.indexes
```

#### Check if an index exists

```ruby
index_exists? = Neon::Node.index?("User")
```

#### Create an index

```ruby
# Default type is exact and provider is lucene
index = Neon::Node.create_index("User", :exact, :lucene)
```

#### Get a node from an index

```ruby
# Exact match
hits = user_index.get(key, value) # hits is an enumerable

# Get a single node if it exists or nil
node_or_nil = hits.single

# Use lucene queries
hits = user_index.query(key, query)

hits = user_index.query(query)
```

#### Add a node to an index

```ruby
user_index.add(node, :email, node[:email])
```

#### Remove a node from an index

```ruby
# Remove a node from user index for the given key-value pair
user_index.remove(node, :email, node[:email])

# Remove a node from user index for the given key
user_index.remove(node, :email)

# Remove a node from user index
user_index.remove(node)
```

#### Delete an index

```ruby
user_index.delete

# Get the score(number of hits) of the most recently fetched node
sore = hits.score
```

#### Auto Indexing

```ruby
# Get the auto index
auto_index = Neon::Node.index

# Enable the auto_index
auto_index.status = true

# Disable the auto_index
auto_index.status = false

# Add a property to the auto index
auto_index.add_property(property)

# Remove a property to the auto index
auto_index.remove_property(property)

# Get nodes with a key-value pair
hits = auto_index.get(key, value)

# Query nodes
hits = auto_index.query(query)
```

### Relationship Indexes
Exactly same api as nodes
### Schema Indexes
This is the preferred way of indexing in Neo4J 2.0. Schema indexes are associated with labels on nodes only and not relationships.
#### Create an index on a label and properties

```ruby
Neon::Node.create_index_on(:Person, property1, property2)
```

#### Find nodes from a schema index

```ruby
# options is a hash of key-value pairs. All nodes matching all values for the given keys are returned.
hits = Neon::Node.index_for(:Person, options)
```

#### Delete an index on a label with properties

```ruby
Neon::Node.delete_index_on(:Person, property1, propert2)
```

#### Add a unique contraint to a label

```ruby
# constraint is :unique by default and as not other contraint is supported right now
# we do not take a contraint argument. This makes our api backwards compatible
Neon::Node.create_contraint_on(:Person, property1, property2)
```

#### Drop a unique contraint on a label

```ruby
Neon::Node.drop_contraint_on(:Person, property1, propert2)
```

There is a shorthand to creating a unique node
#### Create a unique node

```ruby
# arguments are the same as Neon::Node.new
unique_ndoe = Neon::Node.uniq(arguments)
```

## Traversal
TODO
