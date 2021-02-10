# rbs_protobuf

rbs_protobuf is a [RBS](https://github.com/ruby/rbs) generator for Protocol Buffer messages. It parses `.proto` files and generates RBS type signature.

It works as a `protoc` plugin and generates RBSs for `protobuf` gem. (We plan to support `google-protobuf` gem too.)

## Example

This is an example .proto file.

```proto
syntax = "proto2";

package protobuf.example;

message SearchRequest {
  required string query = 1;
  optional int32 page_number = 2;
  optional int32 result_per_page = 3;
}
```

rbs_protobuf will generate the following RBS file including method definitions for each attribute with correct types. 

```rbs
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

And you can type check your Ruby program using the classes with RBS above. 💪

## Installation

Add this line to your application's Gemfile:

```ruby
group :development do
  gem 'rbs_protobuf', require: false
end
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rbs_protobuf

## Usage

Run `protoc` with `--rbs_out` option.

    $ RBS_PROTOBUF_BACKEND=protobuf protoc --rbs_out=sig/protos protos/a.proto

You may need `bundle exec protoc ...` to let bundler set up PATH.

## Type checking

To type check the output, you need to configure your tools to import [gem_rbs_collection](https://github.com/ruby/gem_rbs_collection).

    $ git submodule add https://github.com/ruby/gem_rbs_collection.git vendor/rbs/gem_rbs_collection

If you want to validate your RBS files with `rbs validate`, specify `--repo` option.

    $ rbs --repo=vendor/rbs/gem_rbs_collection/gems -rprotobuf validate

If you want to type check your Ruby program using Steep, add `repo_path` and `library` calls in your `Steepfile`.

```ruby
target :app do
  repo_path "vendor/rbs/gem_rbs_collection/gems"
  library "protobuf"
end
```

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

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test example:typecheck` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

The gem works as a plugin of `protoc` command, so `protoc` command should be available for development.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/square/rbs_protobuf.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
