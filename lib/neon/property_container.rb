module Neon
  # A module to contain REST and Embedded implementation for a property container namely nodes and relationships
  # @author Ujjwal Thaakar
  module PropertyContainer
    # Server implementation for a property container
    module Rest
      include TransactionHelpers::Rest
      # Compares to anothe property container
      #
      # @param other [PropertyContainer] the other property container being compared to
      #
      # @return [Boolean] wether both are the same entities based on their ids and sessions
      def ==(other)
        @id == other.id && @session == other.session
      end

      # Fetch one or more properties e.g. node[:property, :another_Property]. Non existent properties return nil.
      #
      # @param properties [Array<String, Symbol>] the properties to return
      #
      # @return [Array<String>, String] an array of the values of the properties, sorted in the same order they were queried.
      #   In case only a single property is fetche e.g. node[:property] it returns a String containing the corresponding value.
      def [](*properties)
        # Lesson Learnt
        # ==============
        # Don't change what doesn't belong to you
        properties = properties.map(&:to_s)
        run_in_transaction(:[], *properties) do
          node_properties = props # Fetch all properties as this is more efficient than firing a HTTP request for every property
          result = []
          properties.each { |k| result << node_properties[k] }
          # If a single property was asked then return it's value else return an array of values in the correct order
          if properties.length == 1
            result.first
          else
            result
          end
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      # Set one or more properties e.g. node[:property, :another_property] = 5, "Neo4J". nil properties are ignored.
      #
      # @param properties [Array<String, Symbol>] the properties to set.
      # @param values [Array<Numeric, String, Symbol, Array<Numeric, String, Symbol>>] the value to assign to the properties in the order specified.
      #
      # @return [void]
      def []=(*properties, values)
        # Flattent the values to 1 level. This creates an arrray of values in the case only a single value is provided.
        values = [values].flatten(1)
        properties = properties.map(&:to_s)
        run_in_transaction(:[]=, *properties, values) do
          node_properties = props
          Hash[properties.zip(values)].each { |k, v| node_properties[k] = v unless k.nil? }
          self.props = node_properties # Reset all the properties - write simple inefficient code until it proves inefficient
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      # Return all properties of the property container.
      #
      # @return [Hash] a hash of all properties and their values.
      def props
        run_in_transaction(:props) do
          _get_properties || {}
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      # Reset all properties of the property container.
      #
      # @param attributes [Hash] a hash of the property-value pairs to set.
      #
      # @return [void]
      def props=(attributes)
        attributes.delete_if { |property, value| property.nil? || value.nil? } # Remove properties-value pairs where either is nil
        run_in_transaction(:props=, attributes) do
          _reset_properties(attributes)
          return
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      # Delete this entity.
      def del
        run_in_transaction(:del) do
          _delete
          _set_private_vars_to_nil
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      # Destroy this entity i.e. delete it and it's associated entities e.g. relationships of a node
      # and in case of relationships, both its nodes.
      def destroy
        run_in_transaction(:destroy) do
          _destroy # Delete the entity after deleting connected entities
          _set_private_vars_to_nil
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      private
        def _raise_doesnt_exist_anymore_error(e)
          unless @session.nil?
            STDERR.puts e
            raise e 
          end
        end

        def _abstract
          raise "No properties"
        end

        alias :_get_properties :_abstract
        alias :_reset_properties :_abstract
        alias :_set_private_vars_to_nil :_abstract
        alias :_delete :_abstract
        alias :_destroy :_abstract
        alias :query_for :_abstract
        alias :parse_result :_abstract
    end

    # Embedded implementation for a property container
    module Embedded
      include TransactionHelpers::Embedded
      def self.included(klazz)
        raise "Cannot include PropertyContainer::Embedded without JRuby" unless RUBY_PLATFORM == 'java'
      end

      # @return [FixNum] the id of the entity.
      def id
        get_id
      end

      # Compares to anothe property container
      #
      # @param other [PropertyContainer] the other property container being compared to
      #
      # @return [Boolean] wether both are the same entities based on their ids and sessions
      def ==(other)
        id == other.id
      end

      # Fetch one or more properties e.g. node[:property, :another_Property]. Non existent properties return nil.
      #
      # @param properties [Array<String, Symbol>] the properties to return
      #
      # @return [Array<String>, String] an array of the values of the properties, sorted in the same order they were queried.
      #   In case only a single property is fetche e.g. node[ :property] it returns a String containing the corresponding value.
      def [](*properties)
        run_in_transaction do
          properties = _serialize(properties)
          result = []
          properties.each do |k|
            # Result contains the values for the properties asked or nil if they property does not exist
            result << if has_property(k)
              get_property(k)
            else
              nil
            end
          end
          # If a single property was asked then return it's value else return an array of values in the correct order
          if properties.length == 1
            result.first
          else
            result
          end
        end
      end

      # Set one or more properties e.g. node[:property, :another_property] = 5, "Neo4J". nil properties are ignored.
      #
      # @param properties [Array<String, Symbol>] the properties to set.
      # @param values [Array<Numeric, String, Symbol, Array<Numeric, String, Symbol>>] the value to assign to the properties in the order specified.
      #
      # @return [void]
      def []=(*properties, values)
        run_in_transaction do
          # Flattent the values to 1 level. This creates an arrray of values in the case only a single value is provided.
          values = [values].flatten(1)
          attributes = Hash[properties.zip values]
          nil_values = lambda { |_, v| v.nil? } # Resusable lambda
          keys_to_delete = attributes.select(&nil_values).keys # Get the properties to be removed
          attributes.delete_if(&nil_values) # Now remove those properties from attributes
          keys_to_delete.each { |k| remove_property(k) if has_property(k) } # Remove the properties to be deleted if they are valid
          attributes = _serialize(attributes)
          attributes.each { |k, v| set_property(k, v) } # Set property-value pairs for remaining attributes
        end
      end

      # Return all properties of the property container.
      #
      # @return [Hash] a hash of all properties and their values.
      def props
        run_in_transaction do
          result = {} # Initialize results
          get_property_keys.each { |property| result[property] = get_property(property) } # Populate the hash with the container's property-value pairs
          result # Return the result
        end
      end

      # Reset all properties of the property container.
      #
      # @param attributes [Hash] a hash of the property-value pairs to set.
      #
      # @return [void]
      def props=(attributes)
        run_in_transaction do
          attributes.delete_if { |property, value| property.nil? || value.nil? } # Remove properties-value pairs where either is nil before serialization
          attributes = _serialize(attributes)
          get_property_keys.each { |property| remove_property(property) } # Remove all properties
          attributes.each { |property, value| set_property(property, value) } # Set property-value pairs
        end
      end

      # Delete this entity
      def del
        run_in_transaction { delete }
      end

      # Destroy this entity i.e. delete it and it's associated entities e.g. relationships of a node
      # and in case of relationships, both its nodes.
      def destroy
        run_in_transaction { _destroy }
      end

      private
        # Serialize properties and values into approiate type for conversion to Java objects
        def _serialize(*objects)
          result = objects.map do |obj|
            if obj.is_a?(Hash)
              _serialize_hash(obj)
            else
              _appropriate_type_for obj
            end
          end
          if objects.length == 1
            result.first
          else
            result
          end
        end

        # Convert all properties to strings and values to an appropriate type
        def _serialize_hash(hash)
          attributes = {}
          hash.each { |property, value| attributes[property.to_s] = _appropriate_type_for value }
          attributes
        end

        def _appropriate_type_for(value)
          case value
          when String, Numeric, TrueClass, FalseClass
            value # Will be converted by JRuby
          when Array
            # Convert each of the elements to an appropriate type
            # Convert to a Java array of the first element's type. If the types of all elements don't match then the runtime raises an exception.
            result = value.map { |v| _appropriate_type_for v }
            result.to_java(result.first.class.to_s.downcase.to_sym)
          else
            value.to_s # Try and convert to a string
          end
        end

        def _destroy
          raise "No properties"
        end
    end
  end
end
