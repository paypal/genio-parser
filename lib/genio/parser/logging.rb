require 'logger'

module Genio
  module Parser
    class << self
      attr_accessor :logger
    end
    self.logger = Logger.new(STDERR)

    module Logging
      def logger
        Genio::Parser.logger
      end
    end
  end
end
