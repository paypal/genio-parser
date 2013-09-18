module Genio
  module Parser
    module Format
      class IODocs < Base

        class << self

          def to_iodocs(schema)
            { "endpoints" => schema.services.map{|name, service| service_to_iodocs(name, service, schema) } }
          end

          def service_to_iodocs(name, service, schema)
            { "name" => name,
              "methods" => service.operations.map{|name, operation| operation_to_iodocs(name, operation, schema) } }
          end

          URIPropertyName = /{([^}]+)}/
          def operation_to_iodocs(name, operation, schema)
            data = {
              "Name" => name,
              "HTTPMethod" => operation.type,
              "URI" => operation.path.gsub(URIPropertyName,':\1') ,
              "Required" => "Y",
              "Type" => "complex",
              "Parameters" => [],
              "Description" => operation.description || "" }
            if operation.parameters
              data["Parameters"] =
                operation.parameters.map do |name, property|
                  property_to_iodocs(name, property.merge( :required => (property.location == "path") ), schema)
                end
            end
            operation.path.scan(URIPropertyName) do |name|
              if operation.parameters.nil? or operation.parameters[$1].nil?
                property = Types::Property.new(:type => "string", :required => true)
                data["Parameters"] << property_to_iodocs($1, property, schema)
              end
            end
            if operation.request_property
              property  = operation.request_property.merge( :required => true )
              parameter = property_to_iodocs(property.type, property, schema)
              data["Parameters"] += [ parameter ]
              data["RequestContentType"] = "application/json"
            end
            data
          end

          def members_loaded
            @members ||= {}
          end

          def members_for_data_type(data_type, schema)
            return [] if members_loaded[data_type]
            members_loaded[data_type] = true
            members = []
            if data_type.extends and schema.data_types[data_type.extends]
              members += members_for_data_type(schema.data_types[data_type.extends], schema)
            end
            data_type.properties.each{|name, property|
              unless property.readonly
                members.push(property_to_iodocs(name, property, schema))
              end
            }
            members_loaded.delete(data_type)
            members
          end

          def property_to_iodocs(name, property, schema)
            if property.attribute and schema.options[:attribute]
              name = "@#{name}"
            elsif property.package and schema.options[:namespace]
              name = "#{property.package}:#{name}"
            end
            data = {
              "Name" => name,
              "Type" => property.type,
              "ValidatedClass" => property.type,
            }
            data["Description"] = property.description if property.description
            data["Required"] = "Y" if property.required == true
            data["Default"] = property.default unless property.default.nil?
            if property.enum
              data["Type"] = "enumerated"
              data["EnumeratedList"] = property.enum
            elsif schema.data_types[property.type]
              data["Type"]    = "complex"
              data["Members"] = members_for_data_type(schema.data_types[property.type], schema)
              data["Members"] = [ data["Members"] ] if property.array
            end
            data
          end
        end

      end
    end
  end
end
