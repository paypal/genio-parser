module Genio
  module Parser
    module Format
      class Wsdl < Wadl
        def xslt
          @xslt ||= Nokogiri::XSLT(File.read(File.expand_path("../../../../../data/wsdl2meta.xsl", __FILE__)))
        end

        def parse_schema(schema)
          super

          schema.css("services service").each do |service|
            parse_service(service)
          end
        end

        def parse_service(service)
          name = service.attr("name")

          self.services[name] ||= Types::Service.new( :operations => {} )

          service_binding = service.css("binding").first
          if service_binding
            type = service_binding.attr("type")
            self.services[name].package = self.namespaces.find{|k,v| v == type }.try(:first) || type
          end

          service.css("functions function").each do |func|
            options = Hash[func.attributes.map{|k,v| [k, v.value] }]
            operation = Types::Operation.new(options.merge(:path => "/", :type => "POST"))

            request = func.css("parameters variable[part=body]").first
            if request
              operation.request_property = operation_property(request)
              operation.request = operation.request_property.type
            end

            header = func.css("parameters variable[part=header]").first
            if header
              operation.header_property = operation_property(header)
              operation.header = operation.header_property.type
            end

            response = func.css("returns variable[part=body]").first
            if response
              operation.response_property = operation_property(response)
              operation.response = operation.response_property.type
            end

            fault = func.css("throws variable").first
            if fault
              operation.fault_property = operation_property(fault)
              operation.fault = operation.fault_property.type
              self.data_types[operation.fault].fault = true if self.data_types[operation.fault]
            end

            self.services[name].operations[func.attr("name")] = operation
          end
        end

        def operation_property(type)
          property = Types::Property.new(type.attributes.map{|k,v| [k, v.value] })
          property.type = valid_type(property.type)
          element = current_schema.css("elements element[name=#{property.type}]").first
          property.type = valid_type(element.attr("type")) if element and element.attr("type").present?
          property
        end
      end
    end
  end
end
