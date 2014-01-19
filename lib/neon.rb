require "helpers/argument_helpers"
require "helpers/transaction_helpers"
require "neon/session"
require "neon/property_container"
require "neon/node"
require "neon/node/rest"
require "neon/relationship"
require "neon/relationship/rest"
require "neon/transaction"
require "neon/transaction/placebo"
require "neon/transaction/rest"

# If the platform is Java then load all java related files.
if RUBY_PLATFORM == 'java'
  require "java"
  require "neo4j-community"
  Neo4j::Community.load_test_jars!
  require "neon/node/embedded"
  require "neon/relationship/embedded"
end

# @author Ujjwal Thaakar
module Neon
end
