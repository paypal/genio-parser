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
require 'spec_helper'

describe 'Genio::Parser', :vcr => { :cassette_name => 'default' } do
  describe 'Format::Wsdl' do

    before :all do
      VCR.use_cassette('default') do
        @schema = Genio::Parser::Format::Wsdl.new
        @schema.load("http://www.paypalobjects.com/wsdl/PayPalSvc.wsdl")
      end
    end

    it "should have package in all data_types" do
      @schema.data_types.each do |name, data_type|
        data_type.package.should be_present
      end
    end

    it "should handle array type" do
      data_type = @schema.data_types["RefundTransactionRequestType"]
      data_type.properties["RefundItemDetails"].array.should be_true
      data_type.properties["MsgSubID"].array.should_not be_true

      data_type = @schema.data_types["BMCreateButtonRequestType"]
      data_type.properties["ButtonVar"].array.should be_true
      data_type.properties["ButtonType"].array.should_not be_true
    end

    it "should handle enum types" do
      @schema.enum_types.should be_present
      enum_type = @schema.enum_types["ButtonTypeType"]
      enum_type.should_not be_nil
      enum_type.values.should be_a Array
      enum_type.values.should be_include "BUYNOW"

      data_type = @schema.data_types["BMCreateButtonRequestType"]
      data_type.properties["ButtonType"].enum.should eql enum_type.values
    end

    it "should have properties" do
      @schema.namespaces.should be_present
      @schema.services.PayPalAPIInterfaceService.package.should eql "urn:ebay:api:PayPalAPI"
      @schema.attributes.should be_present
      @schema.attributes.targetNamespace.should eql "urn:ebay:api:PayPalAPI"
      @schema.element_form_defaults.should be_present
      @schema.element_form_defaults["urn:ebay:api:PayPalAPI"].should eql "qualified"

    end

    it "should have request and response type" do
      service = @schema.services.PayPalAPIInterfaceService
      service.should_not be_nil
      operation = service.operations.RefundTransaction
      operation.should_not be_nil
      operation.request.should  eql "RefundTransactionReq"
      operation.request_property.name.should eql "RefundTransactionReq"
      operation.response.should eql "RefundTransactionResponseType"
      operation.response_property.name.should eql "RefundTransactionResponse"
      operation.header.should eql "CustomSecurityHeaderType"
      operation.header_property.name.should eql "RequesterCredentials"
    end

    it "should convert simple type" do
      data_type = @schema.data_types.ReceiverInfoType
      data_type.should_not be_nil
      property = data_type.properties.Business
      property.should_not be_nil
      property.type.should eql "string"
    end

    it "should handle attribute type" do
      data_type = @schema.data_types.AmountType
      data_type.should_not be_nil
      data_type.properties.currencyID.attribute.should be_true
      data_type.properties.value.attribute.should_not be_true
    end

  end
end
