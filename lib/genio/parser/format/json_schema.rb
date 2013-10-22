require 'json'

module Genio
  module Parser
    module Format
      class JsonSchema < Base
        include Logging

        attr_accessor :current_schema

        # Load schema
        # == Example
        #   schema.load("path/to/json_schema.json")
        #   schema.load("http://example.com/json_schema.json")
        def load(filename, force = false)
          if data_types[filename] || (!force and data_types[class_name(filename)])
            class_name(filename)
          elsif filename =~ /#./ and self.current_schema
            inline_schema(filename)
          elsif files[filename]
            files[filename]
          else
            files[filename] = class_name(filename)
            parse_file(filename)
          end
        end

        def inline_schema(filename)
          file, names  = filename.split("#", 2)
          names = names.split("/").delete_if(&:empty?)

          schema = self.current_schema
          if file.present?
            read_file(file) do |data|
              schema = JSON.parse(data, :object_class => Types::Base, :max_nesting => 100)
              store_schema(schema) do
                get_inline_schema_klass(names, schema, filename)
              end
            end
          else
            get_inline_schema_klass(names, schema, filename)
          end
        end

        def get_inline_schema_klass(names, schema, filename)
          names.each do |name|
            schema = schema[name] if schema
          end

          if schema
            klass = class_name(class_name(names.join("_")))
            data_types[klass] = {}
            data_types[klass] = parse_object(schema)
            klass
          else
            raise "Unable to find schema #{filename}"
          end
        end

        def store_schema(schema)
          backup = self.current_schema
          self.current_schema = schema
          yield
        ensure
          self.current_schema = backup
        end

        # Parse Given schema file and return class name
        def parse_file(filename)
          klass = class_name(filename)
          read_file(filename) do |data|
            data = JSON.parse(data, :object_class => Types::Base, :max_nesting => 100)
            store_schema(data) do
              if data.type == "object" or data.properties or data.type.is_a? Array   # Check the type is object or not.
                data_types[klass] = {}
                data_types[klass] = parse_object(data)
              elsif data.resources                          # Checkout the schema file contains the services or not
                parse_resource(data)
              end
            end
          end
          klass
        end

        # Parse object schema
        def parse_object(data)
          if data["$ref"]
            return self.data_types[self.load(data["$ref"], true)]
          end

          properties = Types::Base.new

          # Parse each properties
          if data.properties
            data.properties.each do |name, options|
              properties[name] = parse_property(name, options)
            end
          elsif data.type.is_a?(Array)
            data.type.each do |object|
              properties.merge!(parse_object(object).properties)
            end
          end

          # Load extends class.
          if data.extends.is_a? String
            data.extends = self.load(data.extends)
          else
            data.extends = nil
          end

          # Parse array type
          if data.items
            array_type = parse_object(data.items)
            properties.merge!(array_type.properties)
            data.extends ||= array_type.extends
            data.array = true
          end

          data.properties = properties
          Types::DataType.new(data)
        end

        # Parse property.
        def parse_property(name, data)
          data.array = true if data.type == "array"
          data.type  =
            if data["$ref"]               # Check the type is refer to another schema or not
              self.load(data["$ref"])
            elsif data.additionalProperties and data.additionalProperties["$ref"]
              self.load(data.additionalProperties["$ref"])
            elsif data.properties # Check the type has object definition or not
              klass_name = class_name(name)
              data_types[klass_name] = parse_object(data)
              klass_name
            elsif data.type.is_a? Array
              data.union_types = data.type.map do |type|
                parse_object(type)
              end
              "object"
            elsif data.items              # Parse array value type
              array_property = parse_property(name, data.items)
              array_property.type
            else
              data.type                   # Simple type
            end
          Types::Property.new(data)
        rescue => error
          logger.error error.message
          Types::Property.new
        end

        # Parse resource schema
        def parse_resource(data)

          self.endpoint ||= data.rootUrl

          if data.schemas
            data.schemas.each do |name, options|
              data_types[class_name(name)] = true
            end
            data.schemas.each do |name, options|
              data_types[class_name(name)] = parse_object(options)
            end
          end

          parse_services(data.resources, data)
        end

        def parse_services(resources, data)
          # Parse Resources
          resources.each do |name, options|
            service = parse_service(options, data)
            service.path = File.join(data.servicePath, name)
            if services[class_name(name)]
              service.operations.merge!(services[class_name(name)].operations)
            end
            services[class_name(name)] = service
          end
        end

        # Parse each operation in service
        def parse_service(data, service)
          data["methods"] ||= {}

          data["methods"].each do |name, options|
            options.relative_path = options.path
            options.path = File.join(service.servicePath, options.path)
            options.type = options.httpMethod
            if options.request
              options.request_property = parse_property("#{name}_request", options.request)
              options.request = options.request_property.type
            end
            if options.response
              options.response_property = parse_property("#{name}_response", options.response)
              options.response = options.response_property.type
            end
            # Load service parameters
            if options.parameters.nil? and options.type == "GET"
              options.parameters = service.parameters
            end
          end

          data.operations = data["methods"]

          parse_services(data.resources, service) if data.resources

          Types::Service.new(data)
        end

        # Update configured ref links
        def update_ref_paths(data, paths = {})
          paths.each do |path, replace_path|
            replace_path = replace_path.sub(/\/?$/, "/")
            data = data.gsub(/("\$ref"\s*:\s*")#{Regexp.escape(path)}\/?/, "\\1#{replace_path}")
          end
          data
        end

        # Format class name
        # === Example
        #   class_name("credit-card") # return "CreditCard"
        #   class_name("/path/to/payment.json") # return "Payment"
        def class_name(name)
          name, anchor = name.to_s.split("#", 2)
          name = File.basename(name, ".json")
          name = name + "_" + anchor if anchor.present?
          name.gsub(/[^\w]/, "_").camelcase
        end

        # Fix file name format
        def file_name(name)
          name.to_s.gsub(/-/, "_").underscore
        end

        # Map operations based on the Request or Response types.
        def fix_unknown_service
          new_services = Types::Base.new
          services.each do |service_name, service|
            unless data_types[service_name]
              service.operations.each do |operation_name, operation|
                if data_types[operation.request]
                  new_services[operation.request] ||= Types::Base.new( :operations => {} )
                  new_services[operation.request].operations[operation_name] = operation
                elsif data_types[operation.response]
                  new_services[operation.response] ||= Types::Base.new( :operations => {} )
                  new_services[operation.response].operations[operation_name] = operation
                end
              end
            end
          end
          services.merge!(new_services)
        end
      end
    end
  end
end
