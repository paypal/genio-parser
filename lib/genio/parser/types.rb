#
#   Copyright 2013 PayPal Inc.
# 
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
# 
#       http://www.apache.org/licenses/LICENSE-2.0
# 
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#
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
