require "nokogiri"

module Genio
  module Parser
    module Format
      class Wadl < Base

        attr_accessor :current_schema, :namespaces, :attributes, :element_form_defaults

        def load(file)
          return if self.files[file]
          self.files[file] = file

          doc = load_doc(file)
          schema = xslt.transform(doc)
          schema.remove_namespaces!

          parse_schema(schema)
        end

        def load_doc(file)
          logger.info "GET #{file}"
          document = Nokogiri::XML(open(file).read)

          import_document = document.dup
          import_document.remove_namespaces!

          import_document.css("schema import").each do |import|
            if import.attr("schemaLocation")
              import_file = File.join(File.dirname(file), import.attr("schemaLocation"))
              logger.info "GET #{import_file}"
              parent = document.css("definitions types").first
              if parent and parent.children.first
                xml = Nokogiri::XML(open(import_file).read)
                xml.children.each{|element| parent.children.first.before(element) }
              end
            end
          end

          document
        end

        def xslt
          @xslt ||= Nokogiri::XSLT(File.read(File.expand_path("../../../../../data/wadl2meta.xsl", __FILE__)))
        end

        def parse_schema(schema)

          self.current_schema = schema

          self.namespaces ||= Types::Base.new
          schema.css("properties namespace").map{|namespace|
            self.namespaces[namespace.text] = namespace.attr("name")
          }

          self.attributes ||= Types::Base.new
          schema.css("properties attribute").map{|attribute|
            self.attributes[attribute.attr("name")] = attribute.text
          }

          self.element_form_defaults ||= Types::Base.new
          schema.css("properties elementFormDefault").map{|element|
            self.element_form_defaults[element.attr("namespace")] = element.text
          }

          schema.css("elements enum").each do |enum|
            name = valid_class(enum.attr("name"))
            type = Types::EnumType.new(enum.attributes.map{|k,v| [k, v.value] })
            type.values = enum.css("value").map{|element| element.text }
            self.enum_types[name] = type
          end

          # Load data_types
          schema.css("classes class").each do |kls|
            name  = valid_class(kls.attr("name"))
            value = parse_data_type(kls, self.namespaces[kls.attr("package")])
            self.data_types[name] = value
          end

          # Validate property.type in each data_type
          self.data_types.values.each do |data_type|
            data_type.properties.values.each do |property|
              property.type = valid_type(property.type)
            end
          end

          # Set endpoint
          resources = schema.css("resources").first
          self.endpoint ||= resources.attr("base") if resources

          # Load service and operations
          schema.css("resources resource").each do |resource|
            parse_resource(resource)
          end
        end

        def parse_data_type(kls, default_package = nil)
          attrs = Hash[kls.attributes.map{|key, value| [ key, value.value ] }]
          data_type = Types::DataType.new(attrs)

          if data_type.package.blank?
            element = self.current_schema.css("elements element[name=#{data_type.name}]")[0]
            data_type.package = element.attr("package") if element
          end

          if kls.css("extends").any?
            data_type.extends = kls.css("extends").first.attr("name")
          end

          data_type.properties = {}
          kls.css("properties property").each do |property|
            name  = property.attr("name")
            value = Hash[property.attributes.map{|key, value| [ key, value.value ] }]
            value["package"] = default_package if default_package and name != "value"
            data_type.properties[name] = parse_property(value)
          end

          data_type
        end

        def get_element(name, level = 0)
          if name.present?
             element = self.current_schema.css("elements element[name=#{name}]").first
             if element and element.attr("name") != element.attr("type") and level > 0
               get_element(element.attr("type"), level - 1 ) || element
             else
               element
             end
          end
        end

        def parse_property(property)
          property = Types::Property.new(property)

          # Check for complex type
          if property.ref
            property.type = valid_type(property.ref)
          end

          unless property.type
            element = get_element(property.name)
            if element
              property.type = element.attr("type")
              element_package = self.namespaces[element.attr("package")]
              property.package = element_package if element_package
            end
          end

          if property.type.present? and !current_schema.css("classes class[name=#{property.type}]").first
            element = get_element(property.type)
            property.type = element.attr("type") if element and element.attr("type").present?
          end

          # Array type
          if property.max == "unbounded" or property.max.to_i > 1
            property.array = true
          end

          # Required
          if property.min and property.min.to_i > 0
            property.required = true
          end

          # Description
          if property.documentation
            property.description = property.documentation.gsub(/\s+/, " ").strip
          end

          # Enum
          if enum_types[property.type]
            property.enum = enum_types[property.type].values
          end

          property.attribute = true if property.attrib

          property
        end

        def parse_resource(resource)
          resource.css("method").each do |method_object|
            operation = Types::Operation.new(
                          :id => method_object.attr("id"),
                          :type => method_object.attr("name"),
                          :parameters => {},
                          :path => resource.attr("path") )

            resource.css("> param").each do |param|
              operation.parameters[param.attr("name")] =
                Types::Property.new( :type => valid_type(param.attr("type")), :location => "path" )
            end

            method_object.css("param").each do |param|
              operation.parameters[param.attr("name")] =
                Types::Property.new( :type => valid_type(param.attr("type")) )
            end

            request = method_object.css("request representation").first
            if request
              operation.request_property = operation_property(request)
              operation.request = operation.request_property.type
            end

            response = method_object.css("response representation").first
            if response
              operation.response_property = operation_property(response)
              operation.response = operation.response_property.type
            end

            add_operation(operation)
            operation
          end
        end

        def operation_property(type)
          property = Types::Property.new(type.attributes.map{|k,v| [k, v.value] })
          property.type = valid_type(property.element) || "string"
          element = get_element(property.type)
          property.type = valid_type(element.attr(:type)) if element and element.attr(:type).present?
          property
        end

        def add_operation(operation)
          path = operation.path.split("/")
          type =
            if path[-1] =~ /^{/ and path[-2].present? and self.data_types[valid_class(path[-2])]
              valid_class(path[-2])
            elsif path[-2] =~ /^{/ and path[-3].present? and self.data_types[valid_class(path[-3])]
              valid_class(path[-3])
            elsif path[-1].present? and path[-1] !~ /^{/ and self.data_types[valid_class(path[-1])]
              valid_class(path[-1])
            elsif operation.response and self.data_types[operation.response]
              operation.response
            elsif operation.request and self.data_types[operation.request]
              operation.request
            else
              "Service"
            end
          if type
            self.data_types[type] ||= Types::DataType.new( :properties => {} )
            self.services[type] ||= Types::Service.new( :operations => {} )
            name = operation_name(operation)
            self.services[type].operations[name] = operation
          end
        end

        private

        def valid_class(name)
          name.gsub(/-/, "_").camelcase
        end

        def valid_type(name)
          if name
            name = name.gsub(/^.*:/, "")
            type = valid_class(name)
            ( data_types[type] || enum_types[type] ) ? type : name
          end
        end

        def operation_name(operation)
          if operation.id
            operation.id
          elsif operation.type == "GET"
            if operation.path =~ /}$/
              "get"
            else
              "list"
            end
          elsif operation.type == "DELETE"
            "delete"
          elsif operation.path =~ /}\/([^{}]*)$/
            $1.dup
          elsif operation.type == "POST"
            "create"
          else
            "update"
          end
        end

      end
    end
  end
end
