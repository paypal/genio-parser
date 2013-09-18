require 'active_support/all'
require 'uri'
require 'open-uri'

module Genio
  module Parser
    module Format
      class Base
        include Logging

        attr_accessor :files, :services, :data_types, :enum_types, :options, :endpoint

        def initialize(options = {})
          @options = options

          @files      = Types::Base.new( "#" => "self" )
          @services   = Types::Base.new
          @data_types = Types::Base.new
          @enum_types = Types::Base.new
        end

        def to_iodocs
          IODocs.to_iodocs(self)
        end

        def open(file, options = {})
          options[:ssl_verify_mode] ||= 0
          super(file, options)
        end

        def load_files
          @load_files ||= []
        end

        def expand_path(file)
          if load_files.any? and file !~ /^(\/|https?:\/\/)/
            parent_file = load_files.last
            if parent_file =~ /^https?:/
              file = URI.join(parent_file, file).to_s
            else
              file = File.expand_path(file, File.dirname(parent_file))
            end
          end
          file
        end

        def read_file(file, &block)
          file = expand_path(file)
          load_files.push(file)
          logger.info("GET #{file}")
          block.call(open(file).read)
        ensure
          load_files.pop
        end

      end
    end
  end
end
