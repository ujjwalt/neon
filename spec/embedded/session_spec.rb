require "spec_helper"
require "shared_examples/session"

module Neon
  describe Session::Embedded, api: :embedded do
    include_examples "Session"
  end
end
