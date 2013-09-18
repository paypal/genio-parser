require 'genio/parser/version'
require 'genio/parser/logging'

module Genio
  module Parser
    autoload :Types, 'genio/parser/types'
    module Format
      autoload :Base,       'genio/parser/format/base'
      autoload :JsonSchema, 'genio/parser/format/json_schema'
      autoload :IODocs,     'genio/parser/format/iodocs'
      autoload :Wadl,       'genio/parser/format/wadl'
      autoload :Wsdl,       'genio/parser/format/wsdl'
    end
  end
end
