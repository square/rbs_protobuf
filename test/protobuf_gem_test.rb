require "test_helper"

class GoogleProtobufTest < Minitest::Test
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
      upcase_enum: true
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
      upcase_enum: true
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Message < ::Protobuf::Message
  attr_reader name(): true | false

  attr_writer name(): (true | false)?

  def initialize: (?name: (true | false)?) -> void

  def []: (:name) -> (true | false)
        | (::Symbol) -> untyped

  def []=: (:name, (true | false)?) -> (true | false)?
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

    translator = RBSProtobuf::Translator::ProtobufGem.new(input, upcase_enum: false)
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

    translator = RBSProtobuf::Translator::ProtobufGem.new(input, upcase_enum: false)
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

    translator = RBSProtobuf::Translator::ProtobufGem.new(input, upcase_enum: true)
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
      upcase_enum: true
    )
    content = translator.rbs_content(input.proto_file[0])

    assert_equal <<RBS, content
class Foo::Ba_r::Message < ::Protobuf::Message
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
RBS
  end
end
