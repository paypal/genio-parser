require 'spec_helper'

describe 'Genio::Parser', :vcr => { :cassette_name => "default" } do
  describe 'Format' do
    it "parse json_schema" do
      schema = Genio::Parser::Format::JsonSchema.new
      schema.load("https://www.googleapis.com/discovery/v1/apis/urlshortener/v1/rest")
      schema.data_types.keys.should be_include("Url")
    end

    it "parse wsdl" do
      schema = Genio::Parser::Format::Wsdl.new
      schema.load("https://svcs.paypal.com/AdaptivePayments?WSDL")
      schema.data_types.keys.should be_include("ConvertCurrencyRequest")
      schema.data_types.FaultMessage.fault.should be_true

      schema.services.AdaptivePayments.operations.ConvertCurrency.fault.should eql "FaultMessage"
    end

    it "parse wadl" do
      schema = Genio::Parser::Format::Wadl.new
      schema.load("https://api.sandbox.paypal.com/v1/vault/?_wadl")
      schema.data_types.keys.should be_include("CreditCard")
      schema.endpoint.should eql "https://api.sandbox.paypal.com/"

      credit_card = schema.services.CreditCard
      credit_card.should_not be_nil
      credit_card.operations.should_not be_empty
      credit_card.operations.create.request.should eql "CreditCard"
      credit_card.operations.create.response.should eql "CreditCard"
    end

    it "generate iodocs" do
      schema = Genio::Parser::Format::JsonSchema.new
      schema.load("https://www.googleapis.com/discovery/v1/apis/urlshortener/v1/rest")
      iodocs = schema.to_iodocs
      iodocs["endpoints"].should be_any
      iodocs["endpoints"].size.should eql schema.services.size
    end
  end
end
