require "neo4j-cypher"

module Neon
  module Queries
    class << self
      # Queries
      # ========

      # Create a query for fetching properties
      #
      # @param node [Node::Rest] the node for which to fetch properties
      # @param properties [Array] an array of the properties to fetch
      #
      # @return [Array] a two element array consisting of the query string and associated property hash
      def [](properties)
        Neo4j::Cypher.query do
          renamed_properties = properties.map { |prop| node(:n)[prop].as(prop) }
          node(id).as(:n).ret(*renamed_properties)
        end.to_s
      end

      # Create a query for creating nodes
      #
      # @param attributes
      # @param labels
      #
      # @return [Node::Rest]
      def create_node(attributes, labels)
        Neo4j::Cypher.query do
          node.new(attributes, *labels)
        end.to_s
      end

      def query_for(method, *args)
        # Fetch appropriate query and covert the args to a hash corresponding the query parameters
        send method, *args
      end
    end

    module Parser
      class << self
        def parse_result(result, method, *args)
          send method, result, *args
        end

        def [](result, *properties)
          parsed_result = []
          result = result.first
          columns = result["columns"]
          data = result["data"].first["row"].dup
          raise "Corrupted result" if columns.length != properties.length
          for i in 0...properties.length
            parsed_result << if properties[i] == columns[i]
                              data.shift
                            else
                              nil
                            end
          end
          if properties.length == 1
            parsed_result.pop
          else
            parsed_result
          end
        end

        def create_node(result, *node)
          p node
        end
      end
    end
  end
end
