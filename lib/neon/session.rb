require "neon/session/rest"
require "neon/session/embedded"
require "neon/session/invalid_session"

module Neon
  # A session established with a Neo4J database.
  module Session
    class << self
      attr_accessor :current # The current default session running right now.
      
      # Create a new session with the database.
      #
      # @param type [:rest, :embedded] the type of session to create. Any other type will raise a InvalidSesionTypeError.
      # @param args [Array] other args to pass to the session - usually stuff like the address of the database.
      #
      # @return [Session] a new session of type *type* and to the database initiated with *args*.
      def new(type, *args)
        session = case type
          when :rest
            Rest.new(*args)
          when :embedded
            Embedded.new(*args)
          else
            raise InvalidSessionTypeError.new(type)
          end
          # Set the current session unless one already exists
          @current = session unless @current
          session
      end

      # @return [Class] the class of the current session.
      def class
        @current.class
      end

      # @return [Boolean] wether the current session is running or not.
      def running?
        if @current
          @current.running?
        else
          false
        end
      end

      # Starts the current session.
      # @return [Boolean] wether the session started successfully or not.
      def start
        if @current
          @current.start
        else
          false
        end
      end

      # Stops the current session
      # @return [Boolean] wether the session stopped successfully or not.
      def stop
        if @current
          result = @current.stop
          @current = nil if result
          result
        else
          true
        end
      end
    end
  end
end
