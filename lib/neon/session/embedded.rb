module Neon
  module Session
    # A session to an embedded instance of Neo4J
    class Embedded
      include TransactionHelpers::Embedded
      # @!attribute
      #   @return [Boolean] Auto Transaction flag. Enabled by default.
      attr_accessor :auto_tx

      # Create a new session to an embedded database.
      #
      # @param path [String] a path to the location of the embedded database.
      # @param auto_tx [Boolean] an optional flag to set auto transaction (defaults to true).
      #
      # @return [Embedded] a new embedded session.
      def initialize(path = "neo4j", auto_tx = true)
        raise "Cannot start a embedded session without JRuby" if RUBY_PLATFORM != 'java'
        @db_location = path
        @running = false
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

      def location
        @db_location == :impermanent ? :memory : @db_location
      end

      # @return [Boolean] wether the session is running or not.
      def running?
        @running
      end

      # @return [Java::OrgNeo4jKernel::EmbeddedGraphDatabase] the Java graph database backing this session.
      def database
        @db
      end

      # @return [Boolean] wether the session started successfully.
      def start
        return true if @running
        if @db_location == :impermanent
          @db = Java::OrgNeo4jTest::TestGraphDatabaseFactory.new.newImpermanentDatabase()
        else
          @db = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new.newEmbeddedDatabase(@db_location)
        end
        @running = !!@db
      end

      # @return [Boolean] wether the session stopped successfully.
      def stop
        if @running
          @db.shutdown
          @running = false
        end
        true
      end

      def begin_tx
        @db.begin_tx
      end

      def run_tx(&block)
        Transaction::Placebo.run(begin_tx, &block)
      end

      # Nodes
      # Create a new node. If auto_tx is true then we begin a new transaction and commit it after the creation
      def create_node(attributes, labels)
        run_in_transaction { _create_node(attributes, labels) }
      end

      def load(id)
        run_in_transaction { _load(id) }
      end

      def load_rel(id)
        run_in_transaction { _load_rel(id) }
      end

      def to_s
        "Neon Session[#{@db_location}]"
      end

      private
        def _create_node(attributes, labels)
          labels.map! { |label| Java::OrgNeo4jGraphdb::DynamicLabel.label(label) }
          node = @db.create_node(*labels)
          node.props = attributes
          node
        end

        def _load(id)
          @db.get_node_by_id(id)
        end

        def _load_rel(id)
          @db.get_relationship_by_id(id)
        end
    end
  end
end
