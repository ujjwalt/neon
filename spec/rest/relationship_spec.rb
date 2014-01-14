require "spec_helper"
require "shared_examples/relationship"
require "neon/relationship/rest"

module Neon
  describe Relationship::Rest, api: :rest do
    include_examples "Relationship"
  end
end
