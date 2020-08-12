# rbs_protobuf

rbs_protobuf is a [RBS](https://github.com/ruby/rbs) generator for Protocol Buffer messages. It parses `.proto` files and generates RBS type signature.

It works as a `protoc` plugin and generates RBSs for `protobuf` gem. (We plan to support `google-protobuf` gem too.)

## Example

```proto
syntax = "proto2";

package protobuf.example;

message SearchRequest {
  required string query = 1;
  optional int32 page_number = 2;
  optional int32 result_per_page = 3;
}
```

```rbs
# RBS for protobuf gem
# RBS_PROTOBUF_BACKEND=protobuf bundle exec protoc --rbs_out=out example/SearchRequest.proto

module Protobuf
  module Example
    class SearchRequest < ::Protobuf::Message
      attr_reader query(): ::String

      attr_writer query(): ::String?

      attr_reader page_number(): ::Integer

      attr_writer page_number(): ::Integer?

      attr_reader result_per_page(): ::Integer

      attr_writer result_per_page(): ::Integer?

      def initialize: (?query: ::String?, ?page_number: ::Integer?, ?result_per_page: ::Integer?) -> void

      def []: (:query) -> ::String
            | (:page_number) -> ::Integer
            | (:result_per_page) -> ::Integer
            | (::Symbol) -> untyped

      def []=: (:query, ::String?) -> ::String?
             | (:page_number, ::Integer?) -> ::Integer?
             | (:result_per_page, ::Integer?) -> ::Integer?
             | (::Symbol, untyped) -> untyped
    end
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rbs_protobuf'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rbs_protobuf

## Usage

Start `protoc` with `--rbs_out` option.

    $ RBS_PROTOBUF_BACKEND=protobuf bundle exec protoc --rbs_out=output -Iprotos protos/a.proto

### Options

* `RBS_PROTOBUF_BACKEND` specifies the Ruby code generator gem. Supported value is `protobuf`. (We will add `google-protobuf` for `google-protobuf` gem.)
* `PB_UPCASE_ENUMS` is for `protobuf` gem support. Specify the environment variable to make enum value constants upper case.
* `RBS_PROTOBUF_NO_NESTED_NAMESPACE` is to make the RBS declarations flat.

## Supported features

| Protocol Buffer Feature | Support for `protobuf` gem |
|-------------------------|----------------------------|
| Messages                | ✓                          |
| Enums                   | ✓                          |
| Packages                | ✓                          |
| Nested messages         | ✓                          |
| Maps                    | ✓                          |
| Extensions              | ✓                          |
| Services                | Generates stubs            |
| Oneof                   | No support in `protobuf` gem |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

The gem works as a plugin of `protoc` command, so `protoc` command should be available for development.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rbs_protobuf.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
