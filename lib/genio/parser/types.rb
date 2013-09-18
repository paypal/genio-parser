require "genio/parser/types/base"

module Genio
  module Parser
    module Types
      class Service < Base
        attr_accessor :base_path
        attr_accessor :operations
      end

      class Operation < Base
        attr_accessor :type
        attr_accessor :path
        attr_accessor :parameters
        attr_accessor :request
        attr_accessor :response
      end

      class DataType < Base
        attr_accessor :extends
        attr_accessor :properties
      end

      class Property < Base
        attr_accessor :type
        attr_accessor :array
        attr_accessor :min
        attr_accessor :max
        attr_accessor :enum
      end

      class EnumType < Base
        attr_accessor :values
      end
    end
  end
end
