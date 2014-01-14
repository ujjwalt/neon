module Neon
  module TransactionHelpers
    module Rest
      def  run_rest_transaction(method, *args, &block)
        if @session.auto_tx
          yield
        else
          # Fetch the query for this method
          query = query_for method, *args
          tx = @session.begin_tx
          result = tx.run_query query
          tx.success
          tx.close
          result = parse_result(result, method, *args)
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
        if respond_to?(:get_graph_database)
          begin
            tx = get_graph_database.begin_tx
            result = yield if block_given?
            tx.success
            tx.close
          rescue Exception => e
            # Roll back the transaction
            tx.failure
            tx.close
            raise e # Let the exception bubble up
          end
        else
          session = @session || self
          result = if session.auto_tx
                        r = Transaction.run(session, &block)
                        r.pop
                        r = r.pop if r.length == 1
                        r
                      else
                        yield if block_given?
                      end
        end
        result
      end
    end
  end
end
