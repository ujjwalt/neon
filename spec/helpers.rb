require "tmpdir"
load "Rakefile"

module Helpers
  class << self
    def start_server_banner(server_type)
      puts
      msg = "Started #{server_type} Server"
      puts '#'*msg.length
      puts msg
      puts '#'*msg.length
    end
  end

  module Rest
    class << self
      def stop
        Rake.application['neo4j:stop'].invoke
        puts %x[another_neo4j/bin/neo4j stop]
        Neon::Session.stop
      end

      def clean_start
        if @started_server.nil?
          @started_server = true
          at_exit { stop }
          Rake.application['neo4j:reset'].invoke
          puts %x[another_neo4j/bin/neo4j start]
          sleep(1) # give the server some time to breath otherwise it doesn't respond
          Helpers.start_server_banner("REST")
        end
        Neon::Session.stop if Neon::Session.running?
        Neon::Session::Rest.new
        query = <<-EOQ
        START n = node(*)
        OPTIONAL MATCH n-[r]-()
        WHERE ID(n) > 0
        DELETE n, r
        EOQ
        Neon::Session.current.neo.execute_query(query)
      end
    end
  end

  module Embedded
    class << self
      def test_path
        File.join(Dir.tmpdir, "neon-java-#{rand}")
      end

      def stop
        if Neon::Session.running?
          Neon::Session.stop 
        else
          true
        end
      end

      def clean_start
        raise "Could not stop the current database: #{Neon::Session.running?}" unless stop
        # Create a new database
        Neon::Session.new :embedded, test_path
        raise "Could not start embedded database" unless Neon::Session.start
        Helpers.start_server_banner("Embedded")
        graph_db = Neon::Session.current.database
        ggo = Java::OrgNeo4jTooling::GlobalGraphOperations.at(graph_db)

        tx = graph_db.begin_tx
        ggo.all_relationships.each do |rel|
          rel.delete
        end
        tx.success
        tx.finish

        tx = graph_db.begin_tx
        ggo.all_nodes.each do |node|
          node.delete
        end
        tx.success
        tx.close
      end
    end
  end
end