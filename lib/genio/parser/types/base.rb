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
module Genio
  module Parser
    module Types
      class Base < Hash
        def initialize(options = {})
          options.each do |name, value|
            self[name] = value
          end
        end

        def merge(hash)
          dup.merge!(hash)
        end

        def merge!(hash)
          hash.each{|name, value| self[name] = value }
          self
        end

        def [](name)
          name = name.to_s if name.is_a?(Symbol)
          super(name)
        end

        def []=(name, value)
          name = name.to_s if name.is_a?(Symbol)
          super(name, convert(value))
        end

        def convert(value)
          value = Base.new(value) if !value.is_a? Base and value.is_a? Hash
          value
        end

        def method_missing(name, *values)
          if values.size == 0
            self[name]
          elsif values.size == 1 and name =~ /^(.*)=$/
            self[$1] = values.first
          else
            super
          end
        end

        class << self
          def attr_accessor(name)
            define_method name do
              self[name]
            end
            define_method "#{name}=" do |value|
              self[name] = value
            end
          end
        end
      end
    end
  end
end
