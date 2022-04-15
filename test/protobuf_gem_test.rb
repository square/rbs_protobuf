require "test_helper"

class ProtobufGemTest < Minitest::Test
  include TestHelper

  def test_empty_message
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
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
  def initialize: () -> void

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end
RBS
  end

  def test_message_with_optional_base_type
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
  optional string name = 1;
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
  attr_accessor name(): ::String

  def name!: () -> ::String?

  def initialize: (?name: ::String) -> void

  def []: (:name) -> ::String
        | (::Symbol) -> untyped

  def []=: (:name, ::String) -> ::String
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end
RBS
  end

  def test_message_with_required_base_type
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
  required string name = 1;
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
  attr_accessor name(): ::String

  def name!: () -> ::String?

  def initialize: (?name: ::String) -> void

  def []: (:name) -> ::String
        | (::Symbol) -> untyped

  def []=: (:name, ::String) -> ::String
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end
RBS
  end

  def test_message_with_repeated_base_type
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
  repeated string name = 1;
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
  attr_accessor name(): ::Protobuf::Field::FieldArray[::String, ::String]

  def name!: () -> ::Protobuf::Field::FieldArray[::String, ::String]?

  def initialize: (?name: ::Protobuf::Field::FieldArray[::String, ::String]) -> void

  def []: (:name) -> ::Protobuf::Field::FieldArray[::String, ::String]
        | (::Symbol) -> untyped

  def []=: (:name, ::Protobuf::Field::FieldArray[::String, ::String]) -> ::Protobuf::Field::FieldArray[::String, ::String]
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
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
  attr_accessor name(): bool

  def name!: () -> bool?

  def initialize: (?name: bool) -> void

  def []: (:name) -> bool
        | (::Symbol) -> untyped

  def []=: (:name, bool) -> bool
         | (::Symbol, untyped) -> untyped

  def name?: () -> bool

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end
RBS
  end

  def test_message_with_optional_message
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
}

message foo {
  optional Message m1 = 1;
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

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end

class Foo < ::Protobuf::Message
  attr_accessor m1(): ::Message?

  def m1!: () -> ::Message?

  def initialize: (?m1: ::Message?) -> void

  def []: (:m1) -> ::Message?
        | (::Symbol) -> untyped

  def []=: (:m1, ::Message?) -> ::Message?
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Foo
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

  type array = ::Array[Foo | _ToProto]

  type hash[KEY] = ::Hash[KEY, Foo | _ToProto]
end
RBS
  end

  def test_message_with_required_message
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
}

message foo {
  required Message m1 = 1;
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

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end

class Foo < ::Protobuf::Message
  attr_accessor m1(): ::Message

  def m1!: () -> ::Message?

  def initialize: (?m1: ::Message) -> void

  def []: (:m1) -> ::Message
        | (::Symbol) -> untyped

  def []=: (:m1, ::Message) -> ::Message
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Foo
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

  type array = ::Array[Foo | _ToProto]

  type hash[KEY] = ::Hash[KEY, Foo | _ToProto]
end
RBS
  end

  def test_message_with_repeated_message
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
}

message foo {
  repeated Message m1 = 1;
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

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end

class Foo < ::Protobuf::Message
  attr_accessor m1(): ::Protobuf::Field::FieldArray[::Message, ::Message]

  def m1!: () -> ::Protobuf::Field::FieldArray[::Message, ::Message]?

  def initialize: (?m1: ::Protobuf::Field::FieldArray[::Message, ::Message]) -> void

  def []: (:m1) -> ::Protobuf::Field::FieldArray[::Message, ::Message]
        | (::Symbol) -> untyped

  def []=: (:m1, ::Protobuf::Field::FieldArray[::Message, ::Message]) -> ::Protobuf::Field::FieldArray[::Message, ::Message]
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Foo
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

  type array = ::Array[Foo | _ToProto]

  type hash[KEY] = ::Hash[KEY, Foo | _ToProto]
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
# Protobuf options:
#
# - `allow_alias = true`
#
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

  def test_message_with_optional_enum
    input = read_proto(<<EOP)
syntax = "proto2";

enum Size {
  Small = 0;
  Large = 1;
}

message Message {
  optional Size t1 = 1;
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
class Size < ::Protobuf::Enum
  type names = :SMALL | :LARGE

  type strings = "SMALL" | "LARGE"

  type tags = 0 | 1

  type values = names | strings | tags

  attr_reader name(): names

  attr_reader tag(): tags

  SMALL: Size

  LARGE: Size
end

class Message < ::Protobuf::Message
  attr_accessor t1(): ::Size

  def t1=: (::Size::values) -> ::Size::values
         | ...

  def t1!: () -> ::Size?

  def initialize: (?t1: ::Size | ::Size::values) -> void

  def []: (:t1) -> ::Size
        | (::Symbol) -> untyped

  def []=: (:t1, ::Size) -> ::Size
         | (:t1, ::Size::values) -> ::Size::values
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end
RBS
  end

  def test_message_with_required_enum
    input = read_proto(<<EOP)
syntax = "proto2";

enum Size {
  Small = 0;
  Large = 1;
}

message Message {
  required Size t1 = 1;
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
class Size < ::Protobuf::Enum
  type names = :SMALL | :LARGE

  type strings = "SMALL" | "LARGE"

  type tags = 0 | 1

  type values = names | strings | tags

  attr_reader name(): names

  attr_reader tag(): tags

  SMALL: Size

  LARGE: Size
end

class Message < ::Protobuf::Message
  attr_accessor t1(): ::Size

  def t1=: (::Size::values) -> ::Size::values
         | ...

  def t1!: () -> ::Size?

  def initialize: (?t1: ::Size | ::Size::values) -> void

  def []: (:t1) -> ::Size
        | (::Symbol) -> untyped

  def []=: (:t1, ::Size) -> ::Size
         | (:t1, ::Size::values) -> ::Size::values
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end
RBS
  end

  def test_message_with_repeated_enum
    input = read_proto(<<EOP)
syntax = "proto2";

enum Size {
  Small = 0;
  Large = 1;
}

message Message {
  repeated Size t1 = 1;
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
class Size < ::Protobuf::Enum
  type names = :SMALL | :LARGE

  type strings = "SMALL" | "LARGE"

  type tags = 0 | 1

  type values = names | strings | tags

  attr_reader name(): names

  attr_reader tag(): tags

  SMALL: Size

  LARGE: Size
end

class Message < ::Protobuf::Message
  attr_accessor t1(): ::Protobuf::Field::FieldArray[::Size, ::Size | ::Size::values]

  def t1!: () -> ::Protobuf::Field::FieldArray[::Size, ::Size | ::Size::values]?

  def initialize: (?t1: ::Protobuf::Field::FieldArray[::Size, ::Size | ::Size::values]) -> void

  def []: (:t1) -> ::Protobuf::Field::FieldArray[::Size, ::Size | ::Size::values]
        | (::Symbol) -> untyped

  def []=: (:t1, ::Protobuf::Field::FieldArray[::Size, ::Size | ::Size::values]) -> ::Protobuf::Field::FieldArray[::Size, ::Size | ::Size::values]
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
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
      attr_accessor name(): ::String

      def name!: () -> ::String?

      attr_accessor replyTo(): ::Foo::Ba_r::Message?

      def replyTo!: () -> ::Foo::Ba_r::Message?

      def initialize: (?name: ::String, ?replyTo: ::Foo::Ba_r::Message?) -> void

      def []: (:name) -> ::String
            | (:replyTo) -> ::Foo::Ba_r::Message?
            | (::Symbol) -> untyped

      def []=: (:name, ::String) -> ::String
             | (:replyTo, ::Foo::Ba_r::Message?) -> ::Foo::Ba_r::Message?
             | (::Symbol, untyped) -> untyped

      interface _ToProto
        def to_proto: () -> Message
      end

      # The type of `repeated` field.
      type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

      # The type of `map` field.
      type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

      type array = ::Array[Message | _ToProto]

      type hash[KEY] = ::Hash[KEY, Message | _ToProto]
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

  interface _ToProto
    def to_proto: () -> Foo::Ba_r::Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Foo::Ba_r::Message, Foo::Ba_r::Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo::Ba_r::Message, Foo::Ba_r::Message | _ToProto]

  type array = ::Array[Foo::Ba_r::Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Foo::Ba_r::Message | _ToProto]
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
  attr_accessor name(): ::String

  def name!: () -> ::String?

  attr_accessor size(): ::Integer

  def size!: () -> ::Integer?

  def initialize: (?name: ::String, ?size: ::Integer) -> void

  def []: (:name) -> ::String
        | (:size) -> ::Integer
        | (::Symbol) -> untyped

  def []=: (:name, ::String) -> ::String
         | (:size, ::Integer) -> ::Integer
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
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

  def numbers!: () -> ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer]?

  attr_accessor messages(): ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]

  def messages!: () -> ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]?

  def initialize: (?numbers: ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer], ?messages: ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]) -> void

  def []: (:numbers) -> ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer]
        | (:messages) -> ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]
        | (::Symbol) -> untyped

  def []=: (:numbers, ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer]) -> ::Protobuf::Field::FieldHash[::String, ::Integer, ::Integer]
         | (:messages, ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]) -> ::Protobuf::Field::FieldHash[::Integer, ::Message, ::Message]
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
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

  def foos!: () -> ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]?

  def initialize: (?foos: ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]) -> void

  def []: (:foos) -> ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]
        | (::Symbol) -> untyped

  def []=: (:foos, ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]) -> ::Protobuf::Field::FieldHash[::String, ::Foo, ::Foo | ::Foo::values]
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
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

      def foo!: () -> ::Protobuf::Field::FieldHash[::String, ::String, ::String]?

      def initialize: (?foo: ::Protobuf::Field::FieldHash[::String, ::String, ::String]) -> void

      def []: (:foo) -> ::Protobuf::Field::FieldHash[::String, ::String, ::String]
            | (::Symbol) -> untyped

      def []=: (:foo, ::Protobuf::Field::FieldHash[::String, ::String, ::String]) -> ::Protobuf::Field::FieldHash[::String, ::String, ::String]
             | (::Symbol, untyped) -> untyped

      interface _ToProto
        def to_proto: () -> Message2
      end

      # The type of `repeated` field.
      type field_array = ::Protobuf::Field::FieldArray[Message2, Message2 | _ToProto]

      # The type of `map` field.
      type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message2, Message2 | _ToProto]

      type array = ::Array[Message2 | _ToProto]

      type hash[KEY] = ::Hash[KEY, Message2 | _ToProto]
    end

    def initialize: () -> void

    interface _ToProto
      def to_proto: () -> Message
    end

    # The type of `repeated` field.
    type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

    # The type of `map` field.
    type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

    type array = ::Array[Message | _ToProto]

    type hash[KEY] = ::Hash[KEY, Message | _ToProto]
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

    interface _ToProto
      def to_proto: () -> M2
    end

    # The type of `repeated` field.
    type field_array = ::Protobuf::Field::FieldArray[M2, M2 | _ToProto]

    # The type of `map` field.
    type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M2, M2 | _ToProto]

    type array = ::Array[M2 | _ToProto]

    type hash[KEY] = ::Hash[KEY, M2 | _ToProto]
  end

  attr_accessor m(): ::M1::M2?

  def m!: () -> ::M1::M2?

  def initialize: (?m: ::M1::M2?) -> void

  def []: (:m) -> ::M1::M2?
        | (::Symbol) -> untyped

  def []=: (:m, ::M1::M2?) -> ::M1::M2?
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> M1
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[M1, M1 | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M1, M1 | _ToProto]

  type array = ::Array[M1 | _ToProto]

  type hash[KEY] = ::Hash[KEY, M1 | _ToProto]
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

    assert_equal <<'RBS', content
class Account < ::Protobuf::Message
  class Type < ::Protobuf::Enum
    type names = :HUMAN | :BOT

    type strings = "HUMAN" | "BOT"

    type tags = 0 | 1

    type values = names | strings | tags

    attr_reader name(): names

    attr_reader tag(): tags

    HUMAN: Type

    BOT: Type
  end

  attr_accessor type(): ::Account::Type

  def type=: (::Account::Type::values) -> ::Account::Type::values
           | ...

  def type!: () -> ::Account::Type?

  def initialize: (?type: ::Account::Type | ::Account::Type::values) -> void

  def []: (:type) -> ::Account::Type
        | (::Symbol) -> untyped

  def []=: (:type, ::Account::Type) -> ::Account::Type
         | (:type, ::Account::Type::values) -> ::Account::Type::values
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Account
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Account, Account | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Account, Account | _ToProto]

  type array = ::Array[Account | _ToProto]

  type hash[KEY] = ::Hash[KEY, Account | _ToProto]
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

  interface _ToProto
    def to_proto: () -> SearchRequest
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[SearchRequest, SearchRequest | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, SearchRequest, SearchRequest | _ToProto]

  type array = ::Array[SearchRequest | _ToProto]

  type hash[KEY] = ::Hash[KEY, SearchRequest | _ToProto]
end

class SearchResponse < ::Protobuf::Message
  def initialize: () -> void

  interface _ToProto
    def to_proto: () -> SearchResponse
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[SearchResponse, SearchResponse | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, SearchResponse, SearchResponse | _ToProto]

  type array = ::Array[SearchResponse | _ToProto]

  type hash[KEY] = ::Hash[KEY, SearchResponse | _ToProto]
end

class Message < ::Protobuf::Message
  def initialize: () -> void

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
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
  // Name of something
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

    interface _ToProto
      def to_proto: () -> M1
    end

    # The type of `repeated` field.
    type field_array = ::Protobuf::Field::FieldArray[M1, M1 | _ToProto]

    # The type of `map` field.
    type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M1, M1 | _ToProto]

    type array = ::Array[M1 | _ToProto]

    type hash[KEY] = ::Hash[KEY, M1 | _ToProto]
  end
end

class ::Test::M1
  # Name of something
  #
  attr_accessor name(): ::String

  def name!: () -> ::String?

  def []: (:name) -> ::String
        | ...

  def []=: (:name, ::String) -> ::String
         | ...
end

class ::Test::M1
  attr_accessor parent(): ::Test::M1?

  def parent!: () -> ::Test::M1?

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

    interface _ToProto
      def to_proto: () -> M1
    end

    # The type of `repeated` field.
    type field_array = ::Protobuf::Field::FieldArray[M1, M1 | _ToProto]

    # The type of `map` field.
    type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M1, M1 | _ToProto]

    type array = ::Array[M1 | _ToProto]

    type hash[KEY] = ::Hash[KEY, M1 | _ToProto]
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

    interface _ToProto
      def to_proto: () -> M1
    end

    # The type of `repeated` field.
    type field_array = ::Protobuf::Field::FieldArray[M1, M1 | _ToProto]

    # The type of `map` field.
    type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M1, M1 | _ToProto]

    type array = ::Array[M1 | _ToProto]

    type hash[KEY] = ::Hash[KEY, M1 | _ToProto]
  end
end
RBS

    assert_equal <<RBS, stderr.string
#==========================================================
# Printing RBS for extensions from a.proto
#
class ::Test::M1
  attr_accessor name(): ::String

  def name!: () -> ::String?

  def []: (:name) -> ::String
        | ...

  def []=: (:name, ::String) -> ::String
         | ...
end

RBS
  end

  def test_message_with_options
    input = read_proto(<<EOP)
syntax = "proto2";

message Message {
  option deprecated = true;
  optional string name = 1 [deprecated = true];
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
# Protobuf options:
#
# - `deprecated = true`
#
class Message < ::Protobuf::Message
  # Protobuf options:
  #
  # - `deprecated = true`
  #
  attr_accessor name(): ::String

  def name!: () -> ::String?

  def initialize: (?name: ::String) -> void

  def []: (:name) -> ::String
        | (::Symbol) -> untyped

  def []=: (:name, ::String) -> ::String
         | (::Symbol, untyped) -> untyped

  interface _ToProto
    def to_proto: () -> Message
  end

  # The type of `repeated` field.
  type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

  # The type of `map` field.
  type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

  type array = ::Array[Message | _ToProto]

  type hash[KEY] = ::Hash[KEY, Message | _ToProto]
end
RBS
  end
end
