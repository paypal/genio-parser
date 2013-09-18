# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'genio/parser/version'

Gem::Specification.new do |spec|
  spec.name          = "genio-parser"
  spec.version       = Genio::Parser::VERSION
  spec.authors       = ["siddick"]
  spec.email         = ["mebramsha@paypal.com"]
  spec.description   = %q{Parse different schema and generate common object}
  spec.summary       = %q{Parse different schema and generate common object}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + Dir["data/*"] + [ "README.md", "LICENSE.txt" ]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "nokogiri", "~> 1.6"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "simplecov"
end
