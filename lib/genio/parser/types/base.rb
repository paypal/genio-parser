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
