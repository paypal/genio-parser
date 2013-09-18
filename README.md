# Genio Parser

Supported formats are:

* json-schema
* wsdl
* wadl

## Installation

Add this line to your application's Gemfile:

    gem 'genio-parser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install genio-parser

## Usage

```ruby
schema = Genio::Parser::Format::JsonSchema.new
schema.load("path/to/schema.json")

schema.endpoint       # String
schema.data_types     # Hash( String => DataType )
schema.services       # Hash( String => Service )
```

## Object members

DataType:

* extends
* properties

Property:

* type
* array
* enum

Service:

* operations

Operation:

* type
* path
* parameters
* request
* response
