require "test_helper"

class ProtobufGemTest < Minitest::Test
  include TestHelper

  def test_message_with_base_type
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
  optional string name = 1;
  required string Email = 2;
  repeated string postAddress = 3;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Message < ::Protobuf::Message
  attr_reader name(): ::String

  attr_writer name(): ::String?

  attr_reader Email(): ::String

  attr_writer Email(): ::String?

  attr_accessor postAddress(): ::Protobuf::Field::FieldArray[::String, ::String]

  def initialize: (?name: ::String?, ?Email: ::String?, ?postAddress: ::Protobuf::Field::FieldArray[::String, ::String]) -> void

  def []: (:name) -> ::String
        | (:Email) -> ::String
        | (:postAddress) -> ::Protobuf::Field::FieldArray[::String, ::String]
        | (::Symbol) -> untyped

  def []=: (:name, ::String?) -> ::String?
         | (:Email, ::String?) -> ::String?
         | (:postAddress, ::Protobuf::Field::FieldArray[::String, ::String]) -> ::Protobuf::Field::FieldArray[::String, ::String]
         | (::Symbol, untyped) -> untyped
end
RBS
  end

  def test_message_with_bool_predicate
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
  optional bool name = 1;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Message < ::Protobuf::Message
  attr_reader name(): bool

  attr_writer name(): bool?

  def initialize: (?name: bool?) -> void

  def []: (:name) -> bool
        | (::Symbol) -> untyped

  def []=: (:name, bool?) -> bool?
         | (::Symbol, untyped) -> untyped

  def name?: () -> bool
end
RBS
  end

  def test_message_with_message
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
}

message foo {
  optional Message m1 = 1;
  required Message m2 = 2;
  repeated Message m3 = 3;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: false,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Message < ::Protobuf::Message
  def initialize: () -> void
end

class Foo < ::Protobuf::Message
  attr_accessor m1(): ::Message?

  attr_reader m2(): ::Message

  attr_writer m2(): ::Message?

  attr_accessor m3(): ::Protobuf::Field::FieldArray[::Message, ::Message]

  def initialize: (?m1: ::Message?, ?m2: ::Message?, ?m3: ::Protobuf::Field::FieldArray[::Message, ::Message]) -> void

  def []: (:m1) -> ::Message?
        | (:m2) -> ::Message
        | (:m3) -> ::Protobuf::Field::FieldArray[::Message, ::Message]
        | (::Symbol) -> untyped

  def []=: (:m1, ::Message?) -> ::Message?
         | (:m2, ::Message?) -> ::Message?
         | (:m3, ::Protobuf::Field::FieldArray[::Message, ::Message]) -> ::Protobuf::Field::FieldArray[::Message, ::Message]
         | (::Symbol, untyped) -> untyped
end
RBS
  end

  def test_enum
    input = read_proto(<<EOP)
syntax = "proto2";

enum type {
  Foo = 1;
  BAR = 2;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: false,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Type < ::Protobuf::Enum
  type names = :Foo | :BAR

  type strings = "Foo" | "BAR"

  type tags = 1 | 2

  type values = names | strings | tags

  attr_reader name(): names

  attr_reader tag(): tags

  Foo: Type

  BAR: Type
end
RBS
  end

  def test_enum_with_alias
    input = read_proto(<<EOP)
syntax = "proto2";

enum type {
  option allow_alias = true;
  Foo = 1;
  BAR = 1;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: false,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Type < ::Protobuf::Enum
  type names = :Foo | :BAR

  type strings = "Foo" | "BAR"

  type tags = 1

  type values = names | strings | tags

  attr_reader name(): names

  attr_reader tag(): tags

  Foo: Type

  BAR: Type
end
RBS
  end

  def test_message_with_enum
    input = read_proto(<<EOP)
syntax = "proto2";

enum tyPE {
  Foo = 0;
}

message M {
  required tyPE t1 = 1;
  optional tyPE t2 = 2;
  repeated tyPE t3 = 3;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class TyPE < ::Protobuf::Enum
  type names = :FOO

  type strings = "FOO"

  type tags = 0

  type values = names | strings | tags

  attr_reader name(): names

  attr_reader tag(): tags

  FOO: TyPE
end

class M < ::Protobuf::Message
  attr_reader t1(): ::TyPE

  attr_writer t1(): (::TyPE | ::TyPE::values)?

  attr_reader t2(): ::TyPE

  attr_writer t2(): (::TyPE | ::TyPE::values)?

  attr_accessor t3(): ::Protobuf::Field::FieldArray[::TyPE, ::TyPE | ::TyPE::values]

  def initialize: (?t1: (::TyPE | ::TyPE::values)?, ?t2: (::TyPE | ::TyPE::values)?, ?t3: ::Protobuf::Field::FieldArray[::TyPE, ::TyPE | ::TyPE::values]) -> void

  def []: (:t1) -> ::TyPE
        | (:t2) -> ::TyPE
        | (:t3) -> ::Protobuf::Field::FieldArray[::TyPE, ::TyPE | ::TyPE::values]
        | (::Symbol) -> untyped

  def []=: (:t1, (::TyPE | ::TyPE::values)?) -> (::TyPE | ::TyPE::values)?
         | (:t2, (::TyPE | ::TyPE::values)?) -> (::TyPE | ::TyPE::values)?
         | (:t3, ::Protobuf::Field::FieldArray[::TyPE, ::TyPE | ::TyPE::values]) -> ::Protobuf::Field::FieldArray[::TyPE, ::TyPE | ::TyPE::values]
         | (::Symbol, untyped) -> untyped
end
RBS
  end

  def test_message_with_package
    input = read_proto(<<EOP)
syntax = "proto2";

package foo.ba_r;

message Message {
  optional string name = 1;
  optional Message replyTo = 2;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
module Foo
  module Ba_r
    class Message < ::Protobuf::Message
      attr_reader name(): ::String

      attr_writer name(): ::String?

      attr_accessor replyTo(): ::Foo::Ba_r::Message?

      def initialize: (?name: ::String?, ?replyTo: ::Foo::Ba_r::Message?) -> void

      def []: (:name) -> ::String
            | (:replyTo) -> ::Foo::Ba_r::Message?
            | (::Symbol) -> untyped

      def []=: (:name, ::String?) -> ::String?
             | (:replyTo, ::Foo::Ba_r::Message?) -> ::Foo::Ba_r::Message?
             | (::Symbol, untyped) -> untyped
    end
  end
end
RBS
  end

  def test_message_with_package_flat_namespace
    input = read_proto(<<EOP)
syntax = "proto2";

package foo.ba_r;

message Message {
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: false,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Foo::Ba_r::Message < ::Protobuf::Message
  def initialize: () -> void
end
RBS
  end

  def test_message_with_one_of
    # `oneof` is not supported yet in protobuf gem

    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
  oneof test_one_of {
    string name = 1;
    int32 size = 2;
  }
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Message < ::Protobuf::Message
  attr_reader name(): ::String

  attr_writer name(): ::String?

  attr_reader size(): ::Integer

  attr_writer size(): ::Integer?

  def initialize: (?name: ::String?, ?size: ::Integer?) -> void

  def []: (:name) -> ::String
        | (:size) -> ::Integer
        | (::Symbol) -> untyped

  def []=: (:name, ::String?) -> ::String?
         | (:size, ::Integer?) -> ::Integer?
         | (::Symbol, untyped) -> untyped
end
RBS
  end

  def test_message_with_map_to_base_and_message
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
  map<string, int32> numbers = 1;
  map<int32, Message> messages = 2;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Message < ::Protobuf::Message
  attr_accessor numbers(): ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer]

  attr_accessor messages(): ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]

  def initialize: (?numbers: ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer], ?messages: ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]) -> void

  def []: (:numbers) -> ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer]
        | (:messages) -> ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]
        | (::Symbol) -> untyped

  def []=: (:numbers, ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer]) -> ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer]
         | (:messages, ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]) -> ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]
         | (::Symbol, untyped) -> untyped
end
RBS
  end

  def test_message_with_map_to_enum
    # `oneof` is not supported yet in protobuf gem

    input = read_proto(<<EOP)
syntax = "proto2";

enum Foo {
  bar = 0;
  baz = 1;
}

message Message {
  map<string, Foo> foos = 1;
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Foo < ::Protobuf::Enum
  type names = :BAR | :BAZ

  type strings = "BAR" | "BAZ"

  type tags = 0 | 1

  type values = names | strings | tags

  attr_reader name(): names

  attr_reader tag(): tags

  BAR: Foo

  BAZ: Foo
end

class Message < ::Protobuf::Message
  attr_accessor foos(): ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]

  def initialize: (?foos: ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]) -> void

  def []: (:foos) -> ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]
        | (::Symbol) -> untyped

  def []=: (:foos, ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]) -> ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]
         | (::Symbol, untyped) -> untyped
end
RBS
  end

  def test_message_with_map_with_package
    input = read_proto(<<EOP)
syntax = "proto2";

package test1;

message Message {
  message Message2 {
    map<string, string> foo = 1;
  }
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
module Test1
  class Message < ::Protobuf::Message
    class Message2 < ::Protobuf::Message
      attr_accessor foo(): ::Protobuf::Field::FieldHash[::String, ::String, ::String]

      def initialize: (?foo: ::Protobuf::Field::FieldHash[::String, ::String, ::String]) -> void

      def []: (:foo) -> ::Protobuf::Field::FieldHash[::String, ::String, ::String]
            | (::Symbol) -> untyped

      def []=: (:foo, ::Protobuf::Field::FieldHash[::String, ::String, ::String]) -> ::Protobuf::Field::FieldHash[::String, ::String, ::String]
             | (::Symbol, untyped) -> untyped
    end

    def initialize: () -> void
  end
end
RBS
  end

  def test_nested_message
    input = read_proto(<<EOP)
syntax = "proto2";

message M1 {
  optional M2 m = 1;

  message M2 { }
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class M1 < ::Protobuf::Message
  class M2 < ::Protobuf::Message
    def initialize: () -> void
  end

  attr_accessor m(): ::M1::M2?

  def initialize: (?m: ::M1::M2?) -> void

  def []: (:m) -> ::M1::M2?
        | (::Symbol) -> untyped

  def []=: (:m, ::M1::M2?) -> ::M1::M2?
         | (::Symbol, untyped) -> untyped
end
RBS
  end

  def test_nested_enum
    input = read_proto(<<EOP)
syntax = "proto2";

message Account {
  required Type type = 1;

  enum Type {
    Human = 0;
    Bot = 1;
  }
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Account < ::Protobuf::Message
  class Type < ::Protobuf::Enum
    type names = :HUMAN | :BOT

    type strings = \"HUMAN\" | \"BOT\"

    type tags = 0 | 1

    type values = names | strings | tags

    attr_reader name(): names

    attr_reader tag(): tags

    HUMAN: Type

    BOT: Type
  end

  attr_reader type(): ::Account::Type

  attr_writer type(): (::Account::Type | ::Account::Type::values)?

  def initialize: (?type: (::Account::Type | ::Account::Type::values)?) -> void

  def []: (:type) -> ::Account::Type
        | (::Symbol) -> untyped

  def []=: (:type, (::Account::Type | ::Account::Type::values)?) -> (::Account::Type | ::Account::Type::values)?
         | (::Symbol, untyped) -> untyped
end
RBS
  end

  def test_service
    input = read_proto(<<EOP)
syntax = "proto2";

message SearchRequest {
}

message SearchResponse {
}

message Message {
}

service SearchService {
  rpc Search(SearchRequest) returns (SearchResponse);
  rpc SendMessage(Message) returns (Message);
}
EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class SearchRequest < ::Protobuf::Message
  def initialize: () -> void
end

class SearchResponse < ::Protobuf::Message
  def initialize: () -> void
end

class Message < ::Protobuf::Message
  def initialize: () -> void
end

class SearchService < ::Protobuf::Rpc::Service
end
RBS
  end

  def test_extension
    input = read_proto(<<EOP)
syntax = "proto2";

package test;

message M1 {
  extensions 100 to max;
}

extend M1 {
  optional string name = 100;
}

extend M1 {
  optional M1 parent = 101;
}
EOP
    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: true
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
module Test
  class M1 < ::Protobuf::Message
    def initialize: () -> void
  end
end

class ::Test::M1
  attr_reader name(): ::String

  attr_writer name(): ::String?

  def []: (:name) -> ::String
        | ...

  def []=: (:name, ::String?) -> ::String?
         | ...
end

class ::Test::M1
  attr_accessor parent(): ::Test::M1?

  def []: (:parent) -> ::Test::M1?
        | ...

  def []=: (:parent, ::Test::M1?) -> ::Test::M1?
         | ...
end
RBS
  end

  def test_extension_ignore
    input = read_proto(<<EOP)
syntax = "proto2";

package test;

message M1 {
  extensions 100 to max;
}

extend M1 {
  optional string name = 100;
}
EOP
    stderr = StringIO.new

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: nil,
      stderr: stderr
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
module Test
  class M1 < ::Protobuf::Message
    def initialize: () -> void
  end
end
RBS
    assert_equal <<RBS, stderr.string
Extension for `.test.M1` ignored in `a.proto`; Set RBS_PROTOBUF_EXTENSION env var to generate RBS for extensions.
RBS
  end

  def test_extension_print
    input = read_proto(<<EOP)
syntax = "proto2";

package test;

message M1 {
  extensions 100 to max;
}

extend M1 {
  optional string name = 100;
}
EOP
    stderr = StringIO.new

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: :print,
      stderr: stderr
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
module Test
  class M1 < ::Protobuf::Message
    def initialize: () -> void
  end
end
RBS

    assert_equal <<RBS, stderr.string
#==========================================================
# Printing RBS for extensions from a.proto
#
class ::Test::M1
  attr_reader name(): ::String

  attr_writer name(): ::String?

  def []: (:name) -> ::String
        | ...

  def []=: (:name, ::String?) -> ::String?
         | ...
end

RBS
  end
end
