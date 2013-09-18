require 'spec_helper'

describe 'Genio::Parser', :vcr => { :cassette_name => "default" } do
  describe 'Format::JsonSchema' do
    before :all do
      @base = Genio::Parser::Format::JsonSchema.new
    end

    it 'should expand url path' do
      @base.load_files.push("http://api.example.com/a/b/c.json")
      @base.expand_path("new.json").should        eql "http://api.example.com/a/b/new.json"
      @base.expand_path("./new.json").should      eql "http://api.example.com/a/b/new.json"
      @base.expand_path("../new.json").should     eql "http://api.example.com/a/new.json"
      @base.expand_path("../../new.json").should  eql "http://api.example.com/new.json"
      @base.expand_path("../d/new.json").should   eql "http://api.example.com/a/d/new.json"
    end

    it 'should expand file path' do
      @base.load_files.push("/to/schema/a/b/c.json")
      @base.expand_path("new.json").should        eql "/to/schema/a/b/new.json"
      @base.expand_path("./new.json").should      eql "/to/schema/a/b/new.json"
      @base.expand_path("../new.json").should     eql "/to/schema/a/new.json"
      @base.expand_path("../../new.json").should  eql "/to/schema/new.json"
      @base.expand_path("../d/new.json").should   eql "/to/schema/a/d/new.json"
    end

    it 'should support union types' do
      property = @base.parse_property("property", new_type( :type => [ new_type("string"), new_type("number")] ))
      property.type.should eql "object"
      property.union_types.should_not be_nil
    end

    def new_type(options = {})
      options = { :type => options } if options.is_a? String
      Genio::Parser::Types::Base.new(options)
    end

  end
end

