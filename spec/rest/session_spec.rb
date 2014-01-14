require "spec_helper"
require "shared_examples/session"

module Neon
  describe Session::Rest, api: :rest do
    include_examples "Session"
  end
end
