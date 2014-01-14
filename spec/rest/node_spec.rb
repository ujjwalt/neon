require "spec_helper"
require "shared_examples/node"
require "neon/node/rest"

module Neon
  describe Node::Rest, api: :rest do
    include_examples "Node"
  end
end
