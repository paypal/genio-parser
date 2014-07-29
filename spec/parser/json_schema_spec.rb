require 'spec_helper'

describe 'Genio::Parser', :vcr => { :cassette_name => "default" } do
  describe 'Format::JsonSchema' do
    before :all do
      @base = Genio::Parser::Format::JsonSchema.new
      @base.load(File.expand_path("../../data/test.json", __FILE__))
    end

    it 'should expand url path' do
      begin
        @base.load_files.push("http://api.example.com/a/b/c.json")
        @base.expand_path("new.json").should        eql "http://api.example.com/a/b/new.json"
        @base.expand_path("./new.json").should      eql "http://api.example.com/a/b/new.json"
        @base.expand_path("../new.json").should     eql "http://api.example.com/a/new.json"
        @base.expand_path("../../new.json").should  eql "http://api.example.com/new.json"
        @base.expand_path("../d/new.json").should   eql "http://api.example.com/a/d/new.json"
      ensure
        @base.load_files.pop
      end
    end

    it 'should expand file path' do
      begin
        @base.load_files.push("/to/schema/a/b/c.json")
        @base.expand_path("new.json").should        eql "/to/schema/a/b/new.json"
        @base.expand_path("./new.json").should      eql "/to/schema/a/b/new.json"
        @base.expand_path("../new.json").should     eql "/to/schema/a/new.json"
        @base.expand_path("../../new.json").should  eql "/to/schema/new.json"
        @base.expand_path("../d/new.json").should   eql "/to/schema/a/d/new.json"
      ensure
        @base.load_files.pop
      end
    end

    it 'should support union types' do
      property = @base.parse_property("property", new_type( :type => [ new_type("string"), new_type("number")] ))
      property.type.should eql "object"
      property.union_types.should_not be_nil
    end

    it 'should support inline type' do
      test_klass = @base.data_types.Test
      test_klass.properties['inline-type'].type.should eql "PropertiesObject"
    end

    it 'should support oneOf' do
      test_klass = @base.data_types.Test
      test_klass.properties['draft4'].oneOf.map(&:type).should eql ['Test', 'PropertiesObject']
    end

    it 'should generate valid class name' do
      @base.class_name("test.json").should eql "Test"
      @base.class_name("/path/to/test.json").should eql "Test"
      @base.class_name("/path/to/test.json#hello").should eql "TestHello"
      @base.class_name("http://path/to/test.json#/hello/world").should eql "TestHelloWorld"
      @base.class_name("#/hello/world").should eql "HelloWorld"
    end

    describe '#extends' do
      it 'parse file' do
        new_object = @base.parse_object(new_type({ 'type' => 'object', 'extends' => 'test.json' }))
        new_object.extends.should eql 'Test'
      end

      it 'parse ref file' do
        new_object = @base.parse_object(new_type({ 'type' => 'object', 'extends' => { '$ref' => 'test.json' } }))
        new_object.extends.should eql 'Test'
      end

      it 'parse object' do
        new_object = @base.parse_object(new_type({ 'type' => 'object', 'extends' => {
          'properties' => { 'name' => { 'type' => 'string' } } } }))
        new_object.extends.should be_nil
        new_object.properties.name.type.should eql 'string'
      end
    end

    def new_type(options = {})
      options = { :type => options } if options.is_a? String
      Genio::Parser::Types::Base.new(options)
    end

  end
end

