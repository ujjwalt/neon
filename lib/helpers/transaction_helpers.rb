module Neon
  module TransactionHelpers
    module Rest
      include Queries

      def run_in_transaction(method, *args, &block)
        session = @session || self
        if session.auto_tx
          yield if block_given?
        else
          # Fetch the query for this method
          query = Queries::query_for method, *args
          tx = session.begin_tx
          result = tx.run_query query
          tx.success
          tx.close
          result = Queries::Parser::parse_result(result, method, *args)
        end
      end
    end

    module Embedded
      # Used by objects to run a block of code inside a fresh transaction associated
      def run_in_transaction(&block)
        # Retrieve appropriate session based on current type
        # REST:
        #   Session: self
        #   Entity: @session
        # Embedded:
        #   Session: self
        #   Entity: get_graph_database
        session = if respond_to?(:get_graph_database)
                    get_graph_database 
                  else
                    session = self
                  end
        begin
          tx = session.begin_tx
          result = yield if block_given?
          tx.success
          tx.close
        rescue Exception => e
          # Roll back the transaction
          tx.failure
          tx.close
          raise e # Let the exception bubble up
        end
        result
      end
    end
  end
end
