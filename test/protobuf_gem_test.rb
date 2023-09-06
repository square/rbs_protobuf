require "test_helper"

class ProtobufGemTest < Minitest::Test
  include TestHelper

  def test_empty_message
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
      }
    EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { }
      end
    RBS
  end

  def test_message_with_optional_base_type
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        optional string name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        attr_accessor name(): ::String

        def name!: () -> ::String?

        def initialize: (?name: ::String) -> void
                      | (record) -> void

        def []: (:name) -> ::String
              | (::Symbol) -> untyped

        def []=: (:name, ::String) -> ::String
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { name: ::String? }
      end
    RBS
  end

  def test_message_with_required_base_type
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        required string name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        attr_accessor name(): ::String

        def name!: () -> ::String?

        def initialize: (?name: ::String) -> void
                      | (record) -> void

        def []: (:name) -> ::String
              | (::Symbol) -> untyped

        def []=: (:name, ::String) -> ::String
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { name: ::String? }
      end
    RBS
  end

  def test_message_with_repeated_base_type
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        repeated string name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        attr_accessor name(): ::Protobuf::field_array[::String]

        def name=: (::Array[::String]) -> ::Array[::String]
                 | ...

        def name!: () -> ::Protobuf::field_array[::String]?

        def initialize: (?name: ::Array[::String]) -> void
                      | (record) -> void

        def []: (:name) -> ::Protobuf::field_array[::String]
              | (::Symbol) -> untyped

        def []=: (:name, ::Protobuf::field_array[::String]) -> ::Protobuf::field_array[::String]
               | (:name, ::Array[::String]) -> ::Array[::String]
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { name: ::Array[::String]? }
      end
    RBS
  end

  def test_message_with_bool_predicate
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        optional bool name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        attr_accessor name(): bool

        def name!: () -> bool?

        def initialize: (?name: bool) -> void
                      | (record) -> void

        def []: (:name) -> bool
              | (::Symbol) -> untyped

        def []=: (:name, bool) -> bool
               | (::Symbol, untyped) -> untyped

        def name?: () -> bool

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { name: bool? }
      end
    RBS
  end

  def test_message_with_optional_message
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { }
      end

      class Foo < ::Protobuf::Message
        attr_accessor m1(): ::Message?

        def m1=: [M < ::Message::_ToProto] (M?) -> M?
               | ...

        def m1!: () -> ::Message?

        def initialize: (?m1: ::Message::init?) -> void
                      | (record) -> void

        def []: (:m1) -> ::Message?
              | (::Symbol) -> untyped

        def []=: (:m1, ::Message?) -> ::Message?
               | [M < ::Message::_ToProto] (:m1, M?) -> M?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Foo
        end

        # The type of `#initialize` parameter.
        type init = Foo | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

        type array = ::Array[Foo | _ToProto]

        type hash[KEY] = ::Hash[KEY, Foo | _ToProto]

        type record = { :m1 => ::Message::init? }
      end
    RBS
  end

  def test_message_with_required_message
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { }
      end

      class Foo < ::Protobuf::Message
        attr_accessor m1(): ::Message

        def m1=: [M < ::Message::_ToProto] (M) -> M
               | ...

        def m1!: () -> ::Message?

        def initialize: (?m1: ::Message::init) -> void
                      | (record) -> void

        def []: (:m1) -> ::Message
              | (::Symbol) -> untyped

        def []=: (:m1, ::Message) -> ::Message
               | [M < ::Message::_ToProto] (:m1, M) -> M
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Foo
        end

        # The type of `#initialize` parameter.
        type init = Foo | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

        type array = ::Array[Foo | _ToProto]

        type hash[KEY] = ::Hash[KEY, Foo | _ToProto]

        type record = { :m1 => ::Message::init? }
      end
    RBS
  end

  def test_message_with_repeated_message
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { }
      end

      class Foo < ::Protobuf::Message
        attr_accessor m1(): ::Message::field_array

        def m1=: (::Message::array) -> ::Message::array
               | ...

        def m1!: () -> ::Message::field_array?

        def initialize: (?m1: ::Message::array) -> void
                      | (record) -> void

        def []: (:m1) -> ::Message::field_array
              | (::Symbol) -> untyped

        def []=: (:m1, ::Message::field_array) -> ::Message::field_array
               | (:m1, ::Message::array) -> ::Message::array
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Foo
        end

        # The type of `#initialize` parameter.
        type init = Foo | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

        type array = ::Array[Foo | _ToProto]

        type hash[KEY] = ::Hash[KEY, Foo | _ToProto]

        type record = { :m1 => ::Message::array? }
      end
    RBS
  end

  def test_enum
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Type < ::Protobuf::Enum
        type names = :Foo | :BAR

        type strings = "Foo" | "BAR"

        type tags = 1 | 2

        type values = names | strings | tags

        attr_reader name(): names

        attr_reader tag(): tags

        Foo: Type

        BAR: Type

        # The type of `#initialize` parameter.
        type init = Type | values

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Type, Type | values]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Type, Type | values]

        type array = ::Array[Type | values]

        type hash[KEY] = ::Hash[KEY, Type | values]
      end
    RBS
  end

  def test_enum_with_alias
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
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

        # The type of `#initialize` parameter.
        type init = Type | values

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Type, Type | values]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Type, Type | values]

        type array = ::Array[Type | values]

        type hash[KEY] = ::Hash[KEY, Type | values]
      end
    RBS
  end

  def test_message_with_optional_enum
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Size < ::Protobuf::Enum
        type names = :SMALL | :LARGE

        type strings = "SMALL" | "LARGE"

        type tags = 0 | 1

        type values = names | strings | tags

        attr_reader name(): names

        attr_reader tag(): tags

        SMALL: Size

        LARGE: Size

        # The type of `#initialize` parameter.
        type init = Size | values

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Size, Size | values]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Size, Size | values]

        type array = ::Array[Size | values]

        type hash[KEY] = ::Hash[KEY, Size | values]
      end

      class Message < ::Protobuf::Message
        attr_accessor t1(): ::Size

        def t1=: (::Size::values) -> ::Size::values
               | ...

        def t1!: () -> ::Size?

        def initialize: (?t1: ::Size::init) -> void
                      | (record) -> void

        def []: (:t1) -> ::Size
              | (::Symbol) -> untyped

        def []=: (:t1, ::Size) -> ::Size
               | (:t1, ::Size::values) -> ::Size::values
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { :t1 => ::Size::init? }
      end
    RBS
  end

  def test_message_with_required_enum
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Size < ::Protobuf::Enum
        type names = :SMALL | :LARGE

        type strings = "SMALL" | "LARGE"

        type tags = 0 | 1

        type values = names | strings | tags

        attr_reader name(): names

        attr_reader tag(): tags

        SMALL: Size

        LARGE: Size

        # The type of `#initialize` parameter.
        type init = Size | values

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Size, Size | values]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Size, Size | values]

        type array = ::Array[Size | values]

        type hash[KEY] = ::Hash[KEY, Size | values]
      end

      class Message < ::Protobuf::Message
        attr_accessor t1(): ::Size

        def t1=: (::Size::values) -> ::Size::values
               | ...

        def t1!: () -> ::Size?

        def initialize: (?t1: ::Size::init) -> void
                      | (record) -> void

        def []: (:t1) -> ::Size
              | (::Symbol) -> untyped

        def []=: (:t1, ::Size) -> ::Size
               | (:t1, ::Size::values) -> ::Size::values
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { :t1 => ::Size::init? }
      end
    RBS
  end

  def test_message_with_repeated_enum
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Size < ::Protobuf::Enum
        type names = :SMALL | :LARGE

        type strings = "SMALL" | "LARGE"

        type tags = 0 | 1

        type values = names | strings | tags

        attr_reader name(): names

        attr_reader tag(): tags

        SMALL: Size

        LARGE: Size

        # The type of `#initialize` parameter.
        type init = Size | values

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Size, Size | values]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Size, Size | values]

        type array = ::Array[Size | values]

        type hash[KEY] = ::Hash[KEY, Size | values]
      end

      class Message < ::Protobuf::Message
        attr_accessor t1(): ::Size::field_array

        def t1=: (::Size::array) -> ::Size::array
               | ...

        def t1!: () -> ::Size::field_array?

        def initialize: (?t1: ::Size::array) -> void
                      | (record) -> void

        def []: (:t1) -> ::Size::field_array
              | (::Symbol) -> untyped

        def []=: (:t1, ::Size::field_array) -> ::Size::field_array
               | (:t1, ::Size::array) -> ::Size::array
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { :t1 => ::Size::array? }
      end
    RBS
  end

  def test_message_with_package
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Foo
        module Ba_r
          class Message < ::Protobuf::Message
            attr_accessor name(): ::String

            def name!: () -> ::String?

            attr_accessor replyTo(): ::Foo::Ba_r::Message?

            def replyTo=: [M < ::Foo::Ba_r::Message::_ToProto] (M?) -> M?
                        | ...

            def replyTo!: () -> ::Foo::Ba_r::Message?

            def initialize: (?name: ::String, ?replyTo: ::Foo::Ba_r::Message::init?) -> void
                          | (record) -> void

            def []: (:name) -> ::String
                  | (:replyTo) -> ::Foo::Ba_r::Message?
                  | (::Symbol) -> untyped

            def []=: (:name, ::String) -> ::String
                   | (:replyTo, ::Foo::Ba_r::Message?) -> ::Foo::Ba_r::Message?
                   | [M < ::Foo::Ba_r::Message::_ToProto] (:replyTo, M?) -> M?
                   | (::Symbol, untyped) -> untyped

            interface _ToProto
              def to_proto: () -> Message
            end

            # The type of `#initialize` parameter.
            type init = Message | _ToProto | record

            # The type of `repeated` field.
            type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

            # The type of `map` field.
            type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

            type array = ::Array[Message | _ToProto]

            type hash[KEY] = ::Hash[KEY, Message | _ToProto]

            type record = { name: ::String?, replyTo: ::Foo::Ba_r::Message::init? }
          end
        end
      end
    RBS
  end

  def test_message_with_package_flat_namespace
    input = read_proto(<<~EOP)
      syntax = "proto2";

      package foo.ba_r;

      message Message {
      }
    EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: false,
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Foo::Ba_r::Message < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { }
      end
    RBS
  end

  def test_message_with_one_of
    # `oneof` is not supported yet in protobuf gem

    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        attr_accessor name(): ::String

        def name!: () -> ::String?

        attr_accessor size(): ::Integer

        def size!: () -> ::Integer?

        def initialize: (?name: ::String, ?size: ::Integer) -> void
                      | (record) -> void

        def []: (:name) -> ::String
              | (:size) -> ::Integer
              | (::Symbol) -> untyped

        def []=: (:name, ::String) -> ::String
               | (:size, ::Integer) -> ::Integer
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { name: ::String?, size: ::Integer? }
      end
    RBS
  end

  def test_message_with_map_to_base_and_message
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        attr_accessor numbers(): ::Protobuf::field_hash[::String, ::Integer]

        def numbers=: (::Hash[::String, ::Integer]) -> ::Hash[::String, ::Integer]
                    | ...

        def numbers!: () -> ::Protobuf::field_hash[::String, ::Integer]?

        attr_accessor messages(): ::Message::field_hash[::Integer]

        def messages=: (::Message::hash[::Integer]) -> ::Message::hash[::Integer]
                     | ...

        def messages!: () -> ::Message::field_hash[::Integer]?

        def initialize: (?numbers: ::Hash[::String, ::Integer], ?messages: ::Message::hash[::Integer]) -> void
                      | (record) -> void

        def []: (:numbers) -> ::Protobuf::field_hash[::String, ::Integer]
              | (:messages) -> ::Message::field_hash[::Integer]
              | (::Symbol) -> untyped

        def []=: (:numbers, ::Protobuf::field_hash[::String, ::Integer]) -> ::Protobuf::field_hash[::String, ::Integer]
               | (:numbers, ::Hash[::String, ::Integer]) -> ::Hash[::String, ::Integer]
               | (:messages, ::Message::field_hash[::Integer]) -> ::Message::field_hash[::Integer]
               | (:messages, ::Message::hash[::Integer]) -> ::Message::hash[::Integer]
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { numbers: ::Hash[::String, ::Integer]?, messages: ::Message::hash[::Integer]? }
      end
    RBS
  end

  def test_message_with_map_to_enum
    # `oneof` is not supported yet in protobuf gem

    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Foo < ::Protobuf::Enum
        type names = :BAR | :BAZ

        type strings = "BAR" | "BAZ"

        type tags = 0 | 1

        type values = names | strings | tags

        attr_reader name(): names

        attr_reader tag(): tags

        BAR: Foo

        BAZ: Foo

        # The type of `#initialize` parameter.
        type init = Foo | values

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | values]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | values]

        type array = ::Array[Foo | values]

        type hash[KEY] = ::Hash[KEY, Foo | values]
      end

      class Message < ::Protobuf::Message
        attr_accessor foos(): ::Foo::field_hash[::String]

        def foos=: (::Foo::hash[::String]) -> ::Foo::hash[::String]
                 | ...

        def foos!: () -> ::Foo::field_hash[::String]?

        def initialize: (?foos: ::Foo::hash[::String]) -> void
                      | (record) -> void

        def []: (:foos) -> ::Foo::field_hash[::String]
              | (::Symbol) -> untyped

        def []=: (:foos, ::Foo::field_hash[::String]) -> ::Foo::field_hash[::String]
               | (:foos, ::Foo::hash[::String]) -> ::Foo::hash[::String]
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { foos: ::Foo::hash[::String]? }
      end
    RBS
  end

  def test_message_with_map_with_package
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Test1
        class Message < ::Protobuf::Message
          class Message2 < ::Protobuf::Message
            attr_accessor foo(): ::Protobuf::field_hash[::String, ::String]

            def foo=: (::Hash[::String, ::String]) -> ::Hash[::String, ::String]
                    | ...

            def foo!: () -> ::Protobuf::field_hash[::String, ::String]?

            def initialize: (?foo: ::Hash[::String, ::String]) -> void
                          | (record) -> void

            def []: (:foo) -> ::Protobuf::field_hash[::String, ::String]
                  | (::Symbol) -> untyped

            def []=: (:foo, ::Protobuf::field_hash[::String, ::String]) -> ::Protobuf::field_hash[::String, ::String]
                   | (:foo, ::Hash[::String, ::String]) -> ::Hash[::String, ::String]
                   | (::Symbol, untyped) -> untyped

            interface _ToProto
              def to_proto: () -> Message2
            end

            # The type of `#initialize` parameter.
            type init = Message2 | _ToProto | record

            # The type of `repeated` field.
            type field_array = ::Protobuf::Field::FieldArray[Message2, Message2 | _ToProto]

            # The type of `map` field.
            type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message2, Message2 | _ToProto]

            type array = ::Array[Message2 | _ToProto]

            type hash[KEY] = ::Hash[KEY, Message2 | _ToProto]

            type record = { foo: ::Hash[::String, ::String]? }
          end

          def initialize: () -> void

          interface _ToProto
            def to_proto: () -> Message
          end

          # The type of `#initialize` parameter.
          type init = Message | _ToProto

          # The type of `repeated` field.
          type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

          # The type of `map` field.
          type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

          type array = ::Array[Message | _ToProto]

          type hash[KEY] = ::Hash[KEY, Message | _ToProto]

          type record = { }
        end
      end
    RBS
  end

  def test_nested_message
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class M1 < ::Protobuf::Message
        class M2 < ::Protobuf::Message
          def initialize: () -> void

          interface _ToProto
            def to_proto: () -> M2
          end

          # The type of `#initialize` parameter.
          type init = M2 | _ToProto

          # The type of `repeated` field.
          type field_array = ::Protobuf::Field::FieldArray[M2, M2 | _ToProto]

          # The type of `map` field.
          type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M2, M2 | _ToProto]

          type array = ::Array[M2 | _ToProto]

          type hash[KEY] = ::Hash[KEY, M2 | _ToProto]

          type record = { }
        end

        attr_accessor m(): ::M1::M2?

        def m=: [M < ::M1::M2::_ToProto] (M?) -> M?
              | ...

        def m!: () -> ::M1::M2?

        def initialize: (?m: ::M1::M2::init?) -> void
                      | (record) -> void

        def []: (:m) -> ::M1::M2?
              | (::Symbol) -> untyped

        def []=: (:m, ::M1::M2?) -> ::M1::M2?
               | [M < ::M1::M2::_ToProto] (:m, M?) -> M?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> M1
        end

        # The type of `#initialize` parameter.
        type init = M1 | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[M1, M1 | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M1, M1 | _ToProto]

        type array = ::Array[M1 | _ToProto]

        type hash[KEY] = ::Hash[KEY, M1 | _ToProto]

        type record = { m: ::M1::M2::init? }
      end
    RBS
  end

  def test_nested_enum
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~'RBS', content
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

          # The type of `#initialize` parameter.
          type init = Type | values

          # The type of `repeated` field.
          type field_array = ::Protobuf::Field::FieldArray[Type, Type | values]

          # The type of `map` field.
          type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Type, Type | values]

          type array = ::Array[Type | values]

          type hash[KEY] = ::Hash[KEY, Type | values]
        end

        attr_accessor type(): ::Account::Type

        def type=: (::Account::Type::values) -> ::Account::Type::values
                 | ...

        def type!: () -> ::Account::Type?

        def initialize: (?type: ::Account::Type::init) -> void
                      | (record) -> void

        def []: (:type) -> ::Account::Type
              | (::Symbol) -> untyped

        def []=: (:type, ::Account::Type) -> ::Account::Type
               | (:type, ::Account::Type::values) -> ::Account::Type::values
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Account
        end

        # The type of `#initialize` parameter.
        type init = Account | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Account, Account | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Account, Account | _ToProto]

        type array = ::Array[Account | _ToProto]

        type hash[KEY] = ::Hash[KEY, Account | _ToProto]

        type record = { type: ::Account::Type::init? }
      end
    RBS
  end

  def test_service
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class SearchRequest < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> SearchRequest
        end

        # The type of `#initialize` parameter.
        type init = SearchRequest | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[SearchRequest, SearchRequest | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, SearchRequest, SearchRequest | _ToProto]

        type array = ::Array[SearchRequest | _ToProto]

        type hash[KEY] = ::Hash[KEY, SearchRequest | _ToProto]

        type record = { }
      end

      class SearchResponse < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> SearchResponse
        end

        # The type of `#initialize` parameter.
        type init = SearchResponse | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[SearchResponse, SearchResponse | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, SearchResponse, SearchResponse | _ToProto]

        type array = ::Array[SearchResponse | _ToProto]

        type hash[KEY] = ::Hash[KEY, SearchResponse | _ToProto]

        type record = { }
      end

      class Message < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { }
      end

      class SearchService < ::Protobuf::Rpc::Service
        interface _SearchMethod
          def request: () -> ::SearchRequest

          def respond_with: (::SearchResponse::init) -> void
        end

        def search: () -> void

        interface _SendMessageMethod
          def request: () -> ::Message

          def respond_with: (::Message::init) -> void
        end

        def send_message: () -> void
      end
    RBS
  end

  def test_extension
    input = read_proto(<<~EOP)
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
      extension: true,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Test
        class M1 < ::Protobuf::Message
          def initialize: () -> void

          interface _ToProto
            def to_proto: () -> M1
          end

          # The type of `#initialize` parameter.
          type init = M1 | _ToProto

          # The type of `repeated` field.
          type field_array = ::Protobuf::Field::FieldArray[M1, M1 | _ToProto]

          # The type of `map` field.
          type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M1, M1 | _ToProto]

          type array = ::Array[M1 | _ToProto]

          type hash[KEY] = ::Hash[KEY, M1 | _ToProto]

          type record = { }
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

        def parent=: [M < ::Test::M1::_ToProto] (M?) -> M?
                   | ...

        def parent!: () -> ::Test::M1?

        def []: (:parent) -> ::Test::M1?
              | ...

        def []=: (:parent, ::Test::M1?) -> ::Test::M1?
               | [M < ::Test::M1::_ToProto] (:parent, M?) -> M?
               | ...
      end
    RBS
  end

  def test_extension_ignore
    input = read_proto(<<~EOP)
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
      stderr: stderr,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Test
        class M1 < ::Protobuf::Message
          def initialize: () -> void

          interface _ToProto
            def to_proto: () -> M1
          end

          # The type of `#initialize` parameter.
          type init = M1 | _ToProto

          # The type of `repeated` field.
          type field_array = ::Protobuf::Field::FieldArray[M1, M1 | _ToProto]

          # The type of `map` field.
          type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M1, M1 | _ToProto]

          type array = ::Array[M1 | _ToProto]

          type hash[KEY] = ::Hash[KEY, M1 | _ToProto]

          type record = { }
        end
      end
    RBS
    assert_equal <<~TEXT, stderr.string
      Extension for `.test.M1` ignored in `a.proto`; Set RBS_PROTOBUF_EXTENSION env var to generate RBS for extensions.
    TEXT
  end

  def test_extension_print
    input = read_proto(<<~EOP)
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
      stderr: stderr,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Test
        class M1 < ::Protobuf::Message
          def initialize: () -> void

          interface _ToProto
            def to_proto: () -> M1
          end

          # The type of `#initialize` parameter.
          type init = M1 | _ToProto

          # The type of `repeated` field.
          type field_array = ::Protobuf::Field::FieldArray[M1, M1 | _ToProto]

          # The type of `map` field.
          type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, M1, M1 | _ToProto]

          type array = ::Array[M1 | _ToProto]

          type hash[KEY] = ::Hash[KEY, M1 | _ToProto]

          type record = { }
        end
      end
    RBS

    assert_equal <<~TEXT, stderr.string
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

    TEXT
  end

  def test_message_with_options
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: false
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
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
                      | (record) -> void

        def []: (:name) -> ::String
              | (::Symbol) -> untyped

        def []=: (:name, ::String) -> ::String
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { name: ::String? }
      end
    RBS
  end

  def test_message_with_optional_base_type_allow_nil
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        optional string name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: true
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        attr_accessor name(): ::String

        def name=: (::String?) -> ::String?
                 | ...

        def name!: () -> ::String?

        def initialize: (?name: ::String?) -> void
                      | (record) -> void

        def []: (:name) -> ::String
              | (::Symbol) -> untyped

        def []=: (:name, ::String) -> ::String
               | (:name, ::String?) -> ::String?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { name: ::String? }
      end
    RBS
  end

  def test_message_with_repeated_base_type_allow_nil
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        repeated string name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: true
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        attr_accessor name(): ::Protobuf::field_array[::String]

        def name=: (::Protobuf::field_array[::String]?) -> ::Protobuf::field_array[::String]?
                 | (::Array[::String]?) -> ::Array[::String]?
                 | ...

        def name!: () -> ::Protobuf::field_array[::String]?

        def initialize: (?name: ::Array[::String]?) -> void
                      | (record) -> void

        def []: (:name) -> ::Protobuf::field_array[::String]
              | (::Symbol) -> untyped

        def []=: (:name, ::Protobuf::field_array[::String]) -> ::Protobuf::field_array[::String]
               | (:name, ::Protobuf::field_array[::String]?) -> ::Protobuf::field_array[::String]?
               | (:name, ::Array[::String]?) -> ::Array[::String]?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { name: ::Array[::String]? }
      end
    RBS
  end

  def test_message_with_required_message_allow_nil
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: true
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { }
      end

      class Foo < ::Protobuf::Message
        attr_accessor m1(): ::Message

        def m1=: (::Message?) -> ::Message?
               | [M < ::Message::_ToProto] (M?) -> M?
               | ...

        def m1!: () -> ::Message?

        def initialize: (?m1: ::Message::init?) -> void
                      | (record) -> void

        def []: (:m1) -> ::Message
              | (::Symbol) -> untyped

        def []=: (:m1, ::Message) -> ::Message
               | (:m1, ::Message?) -> ::Message?
               | [M < ::Message::_ToProto] (:m1, M?) -> M?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Foo
        end

        # The type of `#initialize` parameter.
        type init = Foo | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

        type array = ::Array[Foo | _ToProto]

        type hash[KEY] = ::Hash[KEY, Foo | _ToProto]

        type record = { :m1 => ::Message::init? }
      end
    RBS
  end

  def test_message_with_repeated_message_allow_nil
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: true
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { }
      end

      class Foo < ::Protobuf::Message
        attr_accessor m1(): ::Message::field_array

        def m1=: (::Message::field_array?) -> ::Message::field_array?
               | (::Message::array?) -> ::Message::array?
               | ...

        def m1!: () -> ::Message::field_array?

        def initialize: (?m1: ::Message::array?) -> void
                      | (record) -> void

        def []: (:m1) -> ::Message::field_array
              | (::Symbol) -> untyped

        def []=: (:m1, ::Message::field_array) -> ::Message::field_array
               | (:m1, ::Message::field_array?) -> ::Message::field_array?
               | (:m1, ::Message::array?) -> ::Message::array?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Foo
        end

        # The type of `#initialize` parameter.
        type init = Foo | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

        type array = ::Array[Foo | _ToProto]

        type hash[KEY] = ::Hash[KEY, Foo | _ToProto]

        type record = { :m1 => ::Message::array? }
      end
    RBS
  end

  def test_message_with_required_enum_allow_nil
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: true
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Size < ::Protobuf::Enum
        type names = :SMALL | :LARGE

        type strings = "SMALL" | "LARGE"

        type tags = 0 | 1

        type values = names | strings | tags

        attr_reader name(): names

        attr_reader tag(): tags

        SMALL: Size

        LARGE: Size

        # The type of `#initialize` parameter.
        type init = Size | values

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Size, Size | values]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Size, Size | values]

        type array = ::Array[Size | values]

        type hash[KEY] = ::Hash[KEY, Size | values]
      end

      class Message < ::Protobuf::Message
        attr_accessor t1(): ::Size

        def t1=: (::Size?) -> ::Size?
               | (::Size::values?) -> ::Size::values?
               | ...

        def t1!: () -> ::Size?

        def initialize: (?t1: ::Size::init?) -> void
                      | (record) -> void

        def []: (:t1) -> ::Size
              | (::Symbol) -> untyped

        def []=: (:t1, ::Size) -> ::Size
               | (:t1, ::Size?) -> ::Size?
               | (:t1, ::Size::values?) -> ::Size::values?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { :t1 => ::Size::init? }
      end
    RBS
  end

  def test_message_with_repeated_enum_allow_nil
    input = read_proto(<<~EOP)
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
      extension: false,
      accept_nil_writer: true
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Size < ::Protobuf::Enum
        type names = :SMALL | :LARGE

        type strings = "SMALL" | "LARGE"

        type tags = 0 | 1

        type values = names | strings | tags

        attr_reader name(): names

        attr_reader tag(): tags

        SMALL: Size

        LARGE: Size

        # The type of `#initialize` parameter.
        type init = Size | values

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Size, Size | values]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Size, Size | values]

        type array = ::Array[Size | values]

        type hash[KEY] = ::Hash[KEY, Size | values]
      end

      class Message < ::Protobuf::Message
        attr_accessor t1(): ::Size::field_array

        def t1=: (::Size::field_array?) -> ::Size::field_array?
               | (::Size::array?) -> ::Size::array?
               | ...

        def t1!: () -> ::Size::field_array?

        def initialize: (?t1: ::Size::array?) -> void
                      | (record) -> void

        def []: (:t1) -> ::Size::field_array
              | (::Symbol) -> untyped

        def []=: (:t1, ::Size::field_array) -> ::Size::field_array
               | (:t1, ::Size::field_array?) -> ::Size::field_array?
               | (:t1, ::Size::array?) -> ::Size::array?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Message
        end

        # The type of `#initialize` parameter.
        type init = Message | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Message, Message | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Message, Message | _ToProto]

        type array = ::Array[Message | _ToProto]

        type hash[KEY] = ::Hash[KEY, Message | _ToProto]

        type record = { :t1 => ::Size::array? }
      end
    RBS
  end

  def test_proto3_message_optional_field
    input = read_proto(<<~PROTO)
      syntax = "proto3";

      message Foo {
        string bar = 1;
        optional string baz = 2;
      }
    PROTO

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: true
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Foo < ::Protobuf::Message
        attr_accessor bar(): ::String

        def bar=: (::String?) -> ::String?
                | ...

        def bar!: () -> ::String?

        attr_accessor baz(): ::String

        def baz=: (::String?) -> ::String?
                | ...

        def baz!: () -> ::String?

        def initialize: (?bar: ::String?, ?baz: ::String?) -> void
                      | (record) -> void

        def []: (:bar) -> ::String
              | (:baz) -> ::String
              | (::Symbol) -> untyped

        def []=: (:bar, ::String) -> ::String
               | (:bar, ::String?) -> ::String?
               | (:baz, ::String) -> ::String
               | (:baz, ::String?) -> ::String?
               | (::Symbol, untyped) -> untyped

        interface _ToProto
          def to_proto: () -> Foo
        end

        # The type of `#initialize` parameter.
        type init = Foo | _ToProto | record

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

        type array = ::Array[Foo | _ToProto]

        type hash[KEY] = ::Hash[KEY, Foo | _ToProto]

        type record = { bar: ::String?, baz: ::String? }
      end
    RBS
  end

  def test_filter
    input = read_proto(<<~PROTO)
      syntax = "proto3";

      message Foo {
        string bar = 1;
        optional string baz = 2;
      }
    PROTO

    filters = [
      -> (name, content, file) {
        _, dirs, decls = RBS::Parser.parse_signature(content)

        content = StringIO.new.tap do |io|
          RBS::Writer.new(out: io).write(
            [
              *dirs,
              RBS::AST::Declarations::Module.new(
                name: TypeName("OuterNamespace"),
                type_params: [],
                members: decls,
                location: nil,
                annotations: [],
                comment: nil,
                self_types: []
              )
            ]
          )
        end.string

        ["hello.rbs", content]
      }
    ]

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      filters,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: true
    )
    translator.generate_rbs!

    output = translator.response.file.find {|file| file.name == "hello.rbs" }

    assert_equal <<~RBS, output.content
      module OuterNamespace
        class Foo < ::Protobuf::Message
          attr_accessor bar(): ::String

          def bar=: (::String?) -> ::String?
                  | ...

          def bar!: () -> ::String?

          attr_accessor baz(): ::String

          def baz=: (::String?) -> ::String?
                  | ...

          def baz!: () -> ::String?

          def initialize: (?bar: ::String?, ?baz: ::String?) -> void
                        | (record) -> void

          def []: (:bar) -> ::String
                | (:baz) -> ::String
                | (::Symbol) -> untyped

          def []=: (:bar, ::String) -> ::String
                 | (:bar, ::String?) -> ::String?
                 | (:baz, ::String) -> ::String
                 | (:baz, ::String?) -> ::String?
                 | (::Symbol, untyped) -> untyped

          interface _ToProto
            def to_proto: () -> Foo
          end

          # The type of `#initialize` parameter.
          type init = Foo | _ToProto | record

          # The type of `repeated` field.
          type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

          # The type of `map` field.
          type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

          type array = ::Array[Foo | _ToProto]

          type hash[KEY] = ::Hash[KEY, Foo | _ToProto]

          type record = { bar: ::String?, baz: ::String? }
        end
      end
    RBS
  end

  def test_filter_return_nil
    input = read_proto(<<~PROTO)
      syntax = "proto3";

      message Foo {
        string bar = 1;
        optional string baz = 2;
      }
    PROTO

    filters = [
      -> (name, content, file) { nil }
    ]

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      filters,
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: true
    )
    translator.generate_rbs!

    assert_nil translator.response.file.find {|file| file.name == "hello.rbs" }
  end

  def test_concat_level
    input = read_protos(
      "foo.proto" => <<~PROTO,
        syntax = "proto3";

        message Foo {
        }
      PROTO
      "foo/bar.proto" => <<~PROTO,
        syntax = "proto3";

        message Bar {
        }
      PROTO
    )

    translator = RBSProtobuf::Translator::ProtobufGem.new(
      input,
      [],
      upcase_enum: true,
      nested_namespace: true,
      extension: false,
      accept_nil_writer: true
    )
    translator.rbs_concat_level = 1
    translator.generate_rbs!

    assert translator.response.file.find {|file| file.name == "foo.rbs" }
    refute translator.response.file.find {|file| file.name == "foo/bar.rbs" }

    file = translator.response.file.find {|file| file.name == "foo.rbs" }
    assert_equal <<~RBS, file.content
      class Foo < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Foo
        end

        # The type of `#initialize` parameter.
        type init = Foo | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Foo, Foo | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Foo, Foo | _ToProto]

        type array = ::Array[Foo | _ToProto]

        type hash[KEY] = ::Hash[KEY, Foo | _ToProto]

        type record = { }
      end

      class Bar < ::Protobuf::Message
        def initialize: () -> void

        interface _ToProto
          def to_proto: () -> Bar
        end

        # The type of `#initialize` parameter.
        type init = Bar | _ToProto

        # The type of `repeated` field.
        type field_array = ::Protobuf::Field::FieldArray[Bar, Bar | _ToProto]

        # The type of `map` field.
        type field_hash[KEY] = ::Protobuf::Field::FieldHash[KEY, Bar, Bar | _ToProto]

        type array = ::Array[Bar | _ToProto]

        type hash[KEY] = ::Hash[KEY, Bar | _ToProto]

        type record = { }
      end
    RBS
  end
end
