require 'bundler/setup'

Bundler.require :default, :test
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes, :erb => true }
  c.configure_rspec_metadata!
end

require 'simplecov'
SimpleCov.start
