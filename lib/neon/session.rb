require "neon/session/rest"
require "neon/session/embedded"
require "neon/session/invalid_session_error"

module Neon
  # A session established with a Neo4J database.
  module Session
    class << self
      attr_accessor :current # The current default session running right now.

      def current=(new_session)
        @current = new_session unless running?
      end

      # @returns [Boolean] whether the new session was set as the new session or not
      def set_current(new_session)
        self.current = new_session
        new_session.current?
      end

      # @return [Class] the class of the current session.
      def class
        @current.class
      end

      # @return [Boolean] whether the current session is running or not.
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

      def location
        @current.location if @current
      end
    end
  end
end
