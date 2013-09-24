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
