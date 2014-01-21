require "neography"

module Neon
  module Session
    class Rest
      include TransactionHelpers::Rest

      attr_reader :neo, :url
      attr_accessor :auto_tx
      
      def initialize(url = "http://localhost:7474", auto_tx = true)
        @neo = Neography::Rest.new url
        @url = url
        @auto_tx = auto_tx
        Session.current = self
      end

      def ==(other_session)
        location == other_session.location
      end

      # @returns [Boolean] whether this is the current sesion or not
      def current?
        self == Session.current
      end

      # These methods make no sense for a rest server so we just return true to make our specs happy
      def start
        true
      end

      alias :stop :start
      alias :running? :start

      def location
        @url
      end

      def create_node(attributes, labels)
        run_in_transaction(:create_node, attributes, labels) do
          node = @neo.create_node(attributes)
          return nil if node.nil?
          @neo.add_label(node, labels)
          Neon::Node::Rest.new(node, self)
        end
      end

      def load(id)
        run_in_transaction(:load, id) do
          node = @neo.get_node(id)
          Neon::Node::Rest.new(node, self)
        end
      end

      def load_rel(id)
        run_in_transaction(:load_rel, id) do
          rel = @neo.get_relationship(id)
          Relationship::Rest.new(rel, self)
        end
      end

      def begin_tx
        Transaction::Rest.begin_tx(self)
      end

      def run_tx(&block)
        Transaction::Placebo.run(begin_tx, &block)
      end

      def to_s
        "Neon Session[#{@url}]"
      end
    end
  end
end