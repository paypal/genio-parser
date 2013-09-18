require 'spec_helper'

describe 'Genio::Parser' do
  describe 'Format::Wadl' do

    before :all do
      VCR.use_cassette('default') do
        @schema = Genio::Parser::Format::Wadl.new
        @schema.load("https://raw.github.com/apigee/wadl-library/master/bitly/bitly-wadl.xml")
      end
    end

    it "should have services" do
      @schema.services.should_not be_empty
      @schema.data_types.should_not be_empty

      @schema.services.Service.operations.size.should eql 15
      @schema.endpoint.should eql "http://api.bitly.com"
    end

    it "should have operation" do
      service = @schema.services.Service
      service.should_not be_nil
      service.operations.shorten.response.should eql "string"
      service.operations.shorten.request.should be_nil
    end

  end
end
