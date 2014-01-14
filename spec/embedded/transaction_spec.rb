require "spec_helper"
require "shared_examples/transaction"

module Neon
  describe "Embedded Transaction", api: :embedded do
    include_examples "Transaction"
  end
end
