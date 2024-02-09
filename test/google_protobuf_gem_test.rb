require "test_helper"

class GoogleProtobufGemTest < Minitest::Test
  include TestHelper

  def test_empty_message
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end
    RBS
  end

  def test_base_types
    input = read_proto(<<~EOP)
      syntax = "proto3";

      message Message {
        double double_field = 1;
        float float_field = 2;
        int64 int64_field = 3;
        uint64 uint64_field = 4;
        int32 int32_field = 5;
        fixed64 fixed64_field = 6;
        fixed32 fixed32_field = 7;
        bool bool_field = 8;
        string string_field = 9;
        bytes bytes_field = 12;
        uint32 uint32_field = 13;
        sfixed32 sfixed32_field = 15;
        sfixed64 sfixed64_field = 16;
        sint32 sint32_field = 17;
        sint64 sint64_field = 18;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
      )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader double_field(): ::Float

        attr_writer double_field(): ::Float | ::Integer

        def clear_double_field: () -> void

        attr_reader float_field(): ::Float

        attr_writer float_field(): ::Float | ::Integer

        def clear_float_field: () -> void

        attr_reader int64_field(): ::Integer

        attr_writer int64_field(): ::Integer | ::Float

        def clear_int64_field: () -> void

        attr_reader uint64_field(): ::Integer

        attr_writer uint64_field(): ::Integer | ::Float

        def clear_uint64_field: () -> void

        attr_reader int32_field(): ::Integer

        attr_writer int32_field(): ::Integer | ::Float

        def clear_int32_field: () -> void

        attr_reader fixed64_field(): ::Integer

        attr_writer fixed64_field(): ::Integer | ::Float

        def clear_fixed64_field: () -> void

        attr_reader fixed32_field(): ::Integer

        attr_writer fixed32_field(): ::Integer | ::Float

        def clear_fixed32_field: () -> void

        attr_accessor bool_field(): bool

        def clear_bool_field: () -> void

        attr_reader string_field(): ::String

        attr_writer string_field(): ::String | ::Symbol

        def clear_string_field: () -> void

        attr_accessor bytes_field(): ::String

        def clear_bytes_field: () -> void

        attr_reader uint32_field(): ::Integer

        attr_writer uint32_field(): ::Integer | ::Float

        def clear_uint32_field: () -> void

        attr_reader sfixed32_field(): ::Integer

        attr_writer sfixed32_field(): ::Integer | ::Float

        def clear_sfixed32_field: () -> void

        attr_reader sfixed64_field(): ::Integer

        attr_writer sfixed64_field(): ::Integer | ::Float

        def clear_sfixed64_field: () -> void

        attr_reader sint32_field(): ::Integer

        attr_writer sint32_field(): ::Integer | ::Float

        def clear_sint32_field: () -> void

        attr_reader sint64_field(): ::Integer

        attr_writer sint64_field(): ::Integer | ::Float

        def clear_sint64_field: () -> void

        def initialize: (?double_field: (::Float | ::Integer)?, ?float_field: (::Float | ::Integer)?, ?int64_field: (::Integer | ::Float)?, ?uint64_field: (::Integer | ::Float)?, ?int32_field: (::Integer | ::Float)?, ?fixed64_field: (::Integer | ::Float)?, ?fixed32_field: (::Integer | ::Float)?, ?bool_field: bool?, ?string_field: (::String | ::Symbol)?, ?bytes_field: ::String?, ?uint32_field: (::Integer | ::Float)?, ?sfixed32_field: (::Integer | ::Float)?, ?sfixed64_field: (::Integer | ::Float)?, ?sint32_field: (::Integer | ::Float)?, ?sint64_field: (::Integer | ::Float)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: (\"double_field\") -> ::Float
              | (\"float_field\") -> ::Float
              | (\"int64_field\") -> ::Integer
              | (\"uint64_field\") -> ::Integer
              | (\"int32_field\") -> ::Integer
              | (\"fixed64_field\") -> ::Integer
              | (\"fixed32_field\") -> ::Integer
              | (\"bool_field\") -> bool
              | (\"string_field\") -> ::String
              | (\"bytes_field\") -> ::String
              | (\"uint32_field\") -> ::Integer
              | (\"sfixed32_field\") -> ::Integer
              | (\"sfixed64_field\") -> ::Integer
              | (\"sint32_field\") -> ::Integer
              | (\"sint64_field\") -> ::Integer
              | (::String) -> untyped

        def []=: (\"double_field\", ::Float | ::Integer) -> void
               | (\"float_field\", ::Float | ::Integer) -> void
               | (\"int64_field\", ::Integer | ::Float) -> void
               | (\"uint64_field\", ::Integer | ::Float) -> void
               | (\"int32_field\", ::Integer | ::Float) -> void
               | (\"fixed64_field\", ::Integer | ::Float) -> void
               | (\"fixed32_field\", ::Integer | ::Float) -> void
               | (\"bool_field\", bool) -> void
               | (\"string_field\", ::String | ::Symbol) -> void
               | (\"bytes_field\", ::String) -> void
               | (\"uint32_field\", ::Integer | ::Float) -> void
               | (\"sfixed32_field\", ::Integer | ::Float) -> void
               | (\"sfixed64_field\", ::Integer | ::Float) -> void
               | (\"sint32_field\", ::Integer | ::Float) -> void
               | (\"sint64_field\", ::Integer | ::Float) -> void
               | (::String, untyped) -> void

        type init_map = { double_field: (::Float | ::Integer)?, float_field: (::Float | ::Integer)?, int64_field: (::Integer | ::Float)?, uint64_field: (::Integer | ::Float)?, int32_field: (::Integer | ::Float)?, fixed64_field: (::Integer | ::Float)?, fixed32_field: (::Integer | ::Float)?, bool_field: bool?, string_field: (::String | ::Symbol)?, bytes_field: ::String?, uint32_field: (::Integer | ::Float)?, sfixed32_field: (::Integer | ::Float)?, sfixed64_field: (::Integer | ::Float)?, sint32_field: (::Integer | ::Float)?, sint64_field: (::Integer | ::Float)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader name(): ::String

        attr_writer name(): ::String | ::Symbol

        def has_name?: () -> bool

        def clear_name: () -> void

        def initialize: (?name: (::String | ::Symbol)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("name") -> ::String
              | (::String) -> untyped

        def []=: ("name", ::String | ::Symbol) -> void
               | (::String, untyped) -> void

        type init_map = { name: (::String | ::Symbol)? }
      end
    RBS
  end

  # proto3 optional fields generate a synthetic oneof, and google-protobuf nonetheless generates
  # the helpers for the oneof.
  def test_message_with_proto3_optional_base_type
    input = read_proto(<<~EOP)
      syntax = "proto3";

      message Message {
        optional string name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader name(): ::String

        attr_writer name(): ::String | ::Symbol

        def has_name?: () -> bool

        def clear_name: () -> void

        attr_reader _name(): ::String?

        def clear__name: () -> void

        def initialize: (?name: (::String | ::Symbol)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("name") -> ::String
              | (::String) -> untyped

        def []=: ("name", ::String | ::Symbol) -> void
               | (::String, untyped) -> void

        type init_map = { name: (::String | ::Symbol)? }
      end
    RBS
  end

  # required constraint is completely ignored in google-protobuf gem.
  def test_message_with_required_base_type
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        required string name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader name(): ::String

        attr_writer name(): ::String | ::Symbol

        def has_name?: () -> bool

        def clear_name: () -> void

        def initialize: (?name: (::String | ::Symbol)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("name") -> ::String
              | (::String) -> untyped

        def []=: ("name", ::String | ::Symbol) -> void
               | (::String, untyped) -> void

        type init_map = { name: (::String | ::Symbol)? }
      end
    RBS
  end

  def test_message_with_implicit_base_type
    input = read_proto(<<~EOP)
      syntax = "proto3";

      message Message {
        string name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader name(): ::String

        attr_writer name(): ::String | ::Symbol

        def clear_name: () -> void

        def initialize: (?name: (::String | ::Symbol)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("name") -> ::String
              | (::String) -> untyped

        def []=: ("name", ::String | ::Symbol) -> void
               | (::String, untyped) -> void

        type init_map = { name: (::String | ::Symbol)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_accessor name(): ::Google::Protobuf::RepeatedField[::String, ::String | ::Symbol]

        def clear_name: () -> void

        def initialize: (?name: ::Array[::String | ::Symbol]?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("name") -> ::Google::Protobuf::RepeatedField[::String, ::String | ::Symbol]
              | (::String) -> untyped

        def []=: ("name", ::Google::Protobuf::RepeatedField[::String, ::String | ::Symbol]) -> void
               | (::String, untyped) -> void

        type init_map = { name: ::Array[::String | ::Symbol]? }
      end
    RBS
  end

  # It generates no bool predicate, contrary to the protobuf gem.
  def test_message_with_bool_predicate
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        optional bool name = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_accessor name(): bool

        def has_name?: () -> bool

        def clear_name: () -> void

        def initialize: (?name: bool?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("name") -> bool
              | (::String) -> untyped

        def []=: ("name", bool) -> void
               | (::String, untyped) -> void

        type init_map = { name: bool? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      class Foo < ::Google::Protobuf::AbstractMessage
        attr_accessor m1(): ::Message?

        def has_m1?: () -> bool

        def clear_m1: () -> void

        def initialize: (?m1: (::Message | ::Message::init_map)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("m1") -> ::Message?
              | (::String) -> untyped

        def []=: ("m1", ::Message?) -> void
               | (::String, untyped) -> void

        type init_map = { m1: (::Message | ::Message::init_map)? }
      end
    RBS
  end

  # proto3 optional fields generate a synthetic oneof, and google-protobuf nonetheless generates
  # the helpers for the oneof.
  def test_message_with_proto3_optional_message
    input = read_proto(<<~EOP)
      syntax = "proto3";

      message Message {
      }

      message foo {
        optional Message m1 = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      class Foo < ::Google::Protobuf::AbstractMessage
        attr_accessor m1(): ::Message?

        def has_m1?: () -> bool

        def clear_m1: () -> void

        attr_reader _m1(): ::Message?

        def clear__m1: () -> void

        def initialize: (?m1: (::Message | ::Message::init_map)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("m1") -> ::Message?
              | (::String) -> untyped

        def []=: ("m1", ::Message?) -> void
               | (::String, untyped) -> void

        type init_map = { m1: (::Message | ::Message::init_map)? }
      end
    RBS
  end

  # required constraint is completely ignored in google-protobuf gem.
  def test_message_with_required_message
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
      }

      message foo {
        required Message m1 = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      class Foo < ::Google::Protobuf::AbstractMessage
        attr_accessor m1(): ::Message?

        def has_m1?: () -> bool

        def clear_m1: () -> void

        def initialize: (?m1: (::Message | ::Message::init_map)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("m1") -> ::Message?
              | (::String) -> untyped

        def []=: ("m1", ::Message?) -> void
               | (::String, untyped) -> void

        type init_map = { m1: (::Message | ::Message::init_map)? }
      end
    RBS
  end

  def test_message_with_implicit_message
    input = read_proto(<<~EOP)
      syntax = "proto3";

      message Message {
      }

      message foo {
        Message m1 = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
      )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      class Foo < ::Google::Protobuf::AbstractMessage
        attr_accessor m1(): ::Message?

        def has_m1?: () -> bool

        def clear_m1: () -> void

        def initialize: (?m1: (::Message | ::Message::init_map)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("m1") -> ::Message?
              | (::String) -> untyped

        def []=: ("m1", ::Message?) -> void
               | (::String, untyped) -> void

        type init_map = { m1: (::Message | ::Message::init_map)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      class Foo < ::Google::Protobuf::AbstractMessage
        attr_accessor m1(): ::Google::Protobuf::RepeatedField[::Message, ::Message]

        def clear_m1: () -> void

        def initialize: (?m1: ::Array[::Message | ::Message::init_map]?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("m1") -> ::Google::Protobuf::RepeatedField[::Message, ::Message]
              | (::String) -> untyped

        def []=: ("m1", ::Google::Protobuf::RepeatedField[::Message, ::Message]) -> void
               | (::String, untyped) -> void

        type init_map = { m1: ::Array[::Message | ::Message::init_map]? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Type
        Foo: 1

        BAR: 2

        attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

        def self.lookup: (1 number) -> :Foo
                       | (2 number) -> :BAR
                       | (::int number) -> names?

        def self.resolve: (:Foo name) -> 1
                        | (:BAR name) -> 2
                        | (::Symbol name) -> numbers?

        type names = :Foo | :BAR

        type strings = "Foo" | "BAR"

        type numbers = 1 | 2
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      # Protobuf options:
      #
      # - `allow_alias = true`
      #
      module Type
        Foo: 1

        BAR: 1

        attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

        def self.lookup: (1 number) -> (:Foo | :BAR)
                       | (::int number) -> names?

        def self.resolve: (:Foo name) -> 1
                        | (:BAR name) -> 1
                        | (::Symbol name) -> numbers?

        type names = :Foo | :BAR

        type strings = "Foo" | "BAR"

        type numbers = 1
      end
    RBS
  end

  # google-protobuf treats proto2 enums like proto3 enums (i.e. they behave like open enums).
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Size
        Small: 0

        Large: 1

        attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

        def self.lookup: (0 number) -> :Small
                       | (1 number) -> :Large
                       | (::int number) -> names?

        def self.resolve: (:Small name) -> 0
                        | (:Large name) -> 1
                        | (::Symbol name) -> numbers?

        type names = :Small | :Large

        type strings = "Small" | "Large"

        type numbers = 0 | 1
      end

      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader t1(): ::Size::names | ::Integer

        attr_writer t1(): ::Size::names | ::Size::strings | ::Integer | ::Float

        attr_reader t1_const(): ::Integer

        def has_t1?: () -> bool

        def clear_t1: () -> void

        def initialize: (?t1: (::Size::names | ::Size::strings | ::Integer | ::Float)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("t1") -> (::Size::names | ::Integer)
              | (::String) -> untyped

        def []=: ("t1", ::Size::names | ::Size::strings | ::Integer | ::Float) -> void
               | (::String, untyped) -> void

        type init_map = { t1: (::Size::names | ::Size::strings | ::Integer | ::Float)? }
      end
    RBS
  end

  # proto3 optional fields generate a synthetic oneof, and google-protobuf nonetheless generates
  # the helpers for the oneof.
  def test_message_with_proto3_optional_enum
    input = read_proto(<<~EOP)
      syntax = "proto3";

      enum Size {
        Small = 0;
        Large = 1;
      }

      message Message {
        optional Size t1 = 1;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Size
        Small: 0

        Large: 1

        attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

        def self.lookup: (0 number) -> :Small
                       | (1 number) -> :Large
                       | (::int number) -> names?

        def self.resolve: (:Small name) -> 0
                        | (:Large name) -> 1
                        | (::Symbol name) -> numbers?

        type names = :Small | :Large

        type strings = "Small" | "Large"

        type numbers = 0 | 1
      end

      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader t1(): ::Size::names | ::Integer

        attr_writer t1(): ::Size::names | ::Size::strings | ::Integer | ::Float

        attr_reader t1_const(): ::Integer

        def has_t1?: () -> bool

        def clear_t1: () -> void

        attr_reader _t1(): (::Size::names | ::Integer)?

        def clear__t1: () -> void

        def initialize: (?t1: (::Size::names | ::Size::strings | ::Integer | ::Float)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("t1") -> (::Size::names | ::Integer)
              | (::String) -> untyped

        def []=: ("t1", ::Size::names | ::Size::strings | ::Integer | ::Float) -> void
               | (::String, untyped) -> void

        type init_map = { t1: (::Size::names | ::Size::strings | ::Integer | ::Float)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Size
        Small: 0

        Large: 1

        attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

        def self.lookup: (0 number) -> :Small
                       | (1 number) -> :Large
                       | (::int number) -> names?

        def self.resolve: (:Small name) -> 0
                        | (:Large name) -> 1
                        | (::Symbol name) -> numbers?

        type names = :Small | :Large

        type strings = "Small" | "Large"

        type numbers = 0 | 1
      end

      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader t1(): ::Size::names | ::Integer

        attr_writer t1(): ::Size::names | ::Size::strings | ::Integer | ::Float

        attr_reader t1_const(): ::Integer

        def has_t1?: () -> bool

        def clear_t1: () -> void

        def initialize: (?t1: (::Size::names | ::Size::strings | ::Integer | ::Float)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("t1") -> (::Size::names | ::Integer)
              | (::String) -> untyped

        def []=: ("t1", ::Size::names | ::Size::strings | ::Integer | ::Float) -> void
               | (::String, untyped) -> void

        type init_map = { t1: (::Size::names | ::Size::strings | ::Integer | ::Float)? }
      end
    RBS
  end

  def test_message_with_implicit_enum
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
      )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Size
        Small: 0

        Large: 1

        attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

        def self.lookup: (0 number) -> :Small
                       | (1 number) -> :Large
                       | (::int number) -> names?

        def self.resolve: (:Small name) -> 0
                        | (:Large name) -> 1
                        | (::Symbol name) -> numbers?

        type names = :Small | :Large

        type strings = "Small" | "Large"

        type numbers = 0 | 1
      end

      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader t1(): ::Size::names | ::Integer

        attr_writer t1(): ::Size::names | ::Size::strings | ::Integer | ::Float

        attr_reader t1_const(): ::Integer

        def has_t1?: () -> bool

        def clear_t1: () -> void

        def initialize: (?t1: (::Size::names | ::Size::strings | ::Integer | ::Float)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("t1") -> (::Size::names | ::Integer)
              | (::String) -> untyped

        def []=: ("t1", ::Size::names | ::Size::strings | ::Integer | ::Float) -> void
               | (::String, untyped) -> void

        type init_map = { t1: (::Size::names | ::Size::strings | ::Integer | ::Float)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Size
        Small: 0

        Large: 1

        attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

        def self.lookup: (0 number) -> :Small
                       | (1 number) -> :Large
                       | (::int number) -> names?

        def self.resolve: (:Small name) -> 0
                        | (:Large name) -> 1
                        | (::Symbol name) -> numbers?

        type names = :Small | :Large

        type strings = "Small" | "Large"

        type numbers = 0 | 1
      end

      class Message < ::Google::Protobuf::AbstractMessage
        attr_accessor t1(): ::Google::Protobuf::RepeatedField[::Size::names | ::Integer, ::Size::names | ::Size::strings | ::Integer | ::Float]

        attr_reader t1_const(): ::Array[::Integer]

        def clear_t1: () -> void

        def initialize: (?t1: ::Array[::Size::names | ::Size::strings | ::Integer | ::Float]?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("t1") -> ::Google::Protobuf::RepeatedField[::Size::names | ::Integer, ::Size::names | ::Size::strings | ::Integer | ::Float]
              | (::String) -> untyped

        def []=: ("t1", ::Google::Protobuf::RepeatedField[::Size::names | ::Integer, ::Size::names | ::Size::strings | ::Integer | ::Float]) -> void
               | (::String, untyped) -> void

        type init_map = { t1: ::Array[::Size::names | ::Size::strings | ::Integer | ::Float]? }
      end
    RBS
  end

  def test_wrappers
    input = read_proto(<<~EOP)
      syntax = "proto3";

      import "google/protobuf/wrappers.proto";

      message Message {
        google.protobuf.DoubleValue double_field = 1;
        google.protobuf.FloatValue float_field = 2;
        google.protobuf.Int64Value int64_field = 3;
        google.protobuf.UInt64Value uint64_field = 4;
        google.protobuf.Int32Value int32_field = 5;
        google.protobuf.UInt32Value uint32_field = 6;
        google.protobuf.BoolValue bool_field = 7;
        google.protobuf.StringValue string_field = 8;
        google.protobuf.BytesValue bytes_field = 9;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[1]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_accessor double_field(): ::Google::Protobuf::DoubleValue?

        attr_reader double_field_as_value(): ::Float?

        attr_writer double_field_as_value(): (::Float | ::Integer)?

        def has_double_field?: () -> bool

        def clear_double_field: () -> void

        attr_accessor float_field(): ::Google::Protobuf::FloatValue?

        attr_reader float_field_as_value(): ::Float?

        attr_writer float_field_as_value(): (::Float | ::Integer)?

        def has_float_field?: () -> bool

        def clear_float_field: () -> void

        attr_accessor int64_field(): ::Google::Protobuf::Int64Value?

        attr_reader int64_field_as_value(): ::Integer?

        attr_writer int64_field_as_value(): (::Integer | ::Float)?

        def has_int64_field?: () -> bool

        def clear_int64_field: () -> void

        attr_accessor uint64_field(): ::Google::Protobuf::UInt64Value?

        attr_reader uint64_field_as_value(): ::Integer?

        attr_writer uint64_field_as_value(): (::Integer | ::Float)?

        def has_uint64_field?: () -> bool

        def clear_uint64_field: () -> void

        attr_accessor int32_field(): ::Google::Protobuf::Int32Value?

        attr_reader int32_field_as_value(): ::Integer?

        attr_writer int32_field_as_value(): (::Integer | ::Float)?

        def has_int32_field?: () -> bool

        def clear_int32_field: () -> void

        attr_accessor uint32_field(): ::Google::Protobuf::UInt32Value?

        attr_reader uint32_field_as_value(): ::Integer?

        attr_writer uint32_field_as_value(): (::Integer | ::Float)?

        def has_uint32_field?: () -> bool

        def clear_uint32_field: () -> void

        attr_accessor bool_field(): ::Google::Protobuf::BoolValue?

        attr_accessor bool_field_as_value(): bool?

        def has_bool_field?: () -> bool

        def clear_bool_field: () -> void

        attr_accessor string_field(): ::Google::Protobuf::StringValue?

        attr_reader string_field_as_value(): ::String?

        attr_writer string_field_as_value(): (::String | ::Symbol)?

        def has_string_field?: () -> bool

        def clear_string_field: () -> void

        attr_accessor bytes_field(): ::Google::Protobuf::BytesValue?

        attr_accessor bytes_field_as_value(): ::String?

        def has_bytes_field?: () -> bool

        def clear_bytes_field: () -> void

        def initialize: (?double_field: (::Google::Protobuf::DoubleValue | ::Google::Protobuf::DoubleValue::init_map)?, ?float_field: (::Google::Protobuf::FloatValue | ::Google::Protobuf::FloatValue::init_map)?, ?int64_field: (::Google::Protobuf::Int64Value | ::Google::Protobuf::Int64Value::init_map)?, ?uint64_field: (::Google::Protobuf::UInt64Value | ::Google::Protobuf::UInt64Value::init_map)?, ?int32_field: (::Google::Protobuf::Int32Value | ::Google::Protobuf::Int32Value::init_map)?, ?uint32_field: (::Google::Protobuf::UInt32Value | ::Google::Protobuf::UInt32Value::init_map)?, ?bool_field: (::Google::Protobuf::BoolValue | ::Google::Protobuf::BoolValue::init_map)?, ?string_field: (::Google::Protobuf::StringValue | ::Google::Protobuf::StringValue::init_map)?, ?bytes_field: (::Google::Protobuf::BytesValue | ::Google::Protobuf::BytesValue::init_map)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: (\"double_field\") -> ::Google::Protobuf::DoubleValue?
              | (\"float_field\") -> ::Google::Protobuf::FloatValue?
              | (\"int64_field\") -> ::Google::Protobuf::Int64Value?
              | (\"uint64_field\") -> ::Google::Protobuf::UInt64Value?
              | (\"int32_field\") -> ::Google::Protobuf::Int32Value?
              | (\"uint32_field\") -> ::Google::Protobuf::UInt32Value?
              | (\"bool_field\") -> ::Google::Protobuf::BoolValue?
              | (\"string_field\") -> ::Google::Protobuf::StringValue?
              | (\"bytes_field\") -> ::Google::Protobuf::BytesValue?
              | (::String) -> untyped

        def []=: (\"double_field\", ::Google::Protobuf::DoubleValue?) -> void
               | (\"float_field\", ::Google::Protobuf::FloatValue?) -> void
               | (\"int64_field\", ::Google::Protobuf::Int64Value?) -> void
               | (\"uint64_field\", ::Google::Protobuf::UInt64Value?) -> void
               | (\"int32_field\", ::Google::Protobuf::Int32Value?) -> void
               | (\"uint32_field\", ::Google::Protobuf::UInt32Value?) -> void
               | (\"bool_field\", ::Google::Protobuf::BoolValue?) -> void
               | (\"string_field\", ::Google::Protobuf::StringValue?) -> void
               | (\"bytes_field\", ::Google::Protobuf::BytesValue?) -> void
               | (::String, untyped) -> void

        type init_map = { double_field: (::Google::Protobuf::DoubleValue | ::Google::Protobuf::DoubleValue::init_map)?, float_field: (::Google::Protobuf::FloatValue | ::Google::Protobuf::FloatValue::init_map)?, int64_field: (::Google::Protobuf::Int64Value | ::Google::Protobuf::Int64Value::init_map)?, uint64_field: (::Google::Protobuf::UInt64Value | ::Google::Protobuf::UInt64Value::init_map)?, int32_field: (::Google::Protobuf::Int32Value | ::Google::Protobuf::Int32Value::init_map)?, uint32_field: (::Google::Protobuf::UInt32Value | ::Google::Protobuf::UInt32Value::init_map)?, bool_field: (::Google::Protobuf::BoolValue | ::Google::Protobuf::BoolValue::init_map)?, string_field: (::Google::Protobuf::StringValue | ::Google::Protobuf::StringValue::init_map)?, bytes_field: (::Google::Protobuf::BytesValue | ::Google::Protobuf::BytesValue::init_map)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Foo
        module BaR
          class Message < ::Google::Protobuf::AbstractMessage
            attr_reader name(): ::String

            attr_writer name(): ::String | ::Symbol

            def has_name?: () -> bool

            def clear_name: () -> void

            attr_accessor replyTo(): ::Foo::BaR::Message?

            def has_replyTo?: () -> bool

            def clear_replyTo: () -> void

            def initialize: (?name: (::String | ::Symbol)?, ?replyTo: (::Foo::BaR::Message | ::Foo::BaR::Message::init_map)?) -> void
                          | (::Hash[::Symbol | ::String, untyped] attributes) -> void

            def []: (\"name\") -> ::String
                  | (\"replyTo\") -> ::Foo::BaR::Message?
                  | (::String) -> untyped

            def []=: (\"name\", ::String | ::Symbol) -> void
                   | (\"replyTo\", ::Foo::BaR::Message?) -> void
                   | (::String, untyped) -> void

            type init_map = { name: (::String | ::Symbol)?, replyTo: (::Foo::BaR::Message | ::Foo::BaR::Message::init_map)? }
          end
        end
      end
    RBS
  end


  def test_message_with_renamed_package
    input = read_proto(<<~EOP)
      syntax = "proto2";

      package foo.ba_r;

      option ruby_package = "FooPb::BarPb";

      message Message {
        optional string name = 1;
        optional Message replyTo = 2;
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
      )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module FooPb
        module BarPb
          class Message < ::Google::Protobuf::AbstractMessage
            attr_reader name(): ::String

            attr_writer name(): ::String | ::Symbol

            def has_name?: () -> bool

            def clear_name: () -> void

            attr_accessor replyTo(): ::FooPb::BarPb::Message?

            def has_replyTo?: () -> bool

            def clear_replyTo: () -> void

            def initialize: (?name: (::String | ::Symbol)?, ?replyTo: (::FooPb::BarPb::Message | ::FooPb::BarPb::Message::init_map)?) -> void
                          | (::Hash[::Symbol | ::String, untyped] attributes) -> void

            def []: (\"name\") -> ::String
                  | (\"replyTo\") -> ::FooPb::BarPb::Message?
                  | (::String) -> untyped

            def []=: (\"name\", ::String | ::Symbol) -> void
                   | (\"replyTo\", ::FooPb::BarPb::Message?) -> void
                   | (::String, untyped) -> void

            type init_map = { name: (::String | ::Symbol)?, replyTo: (::FooPb::BarPb::Message | ::FooPb::BarPb::Message::init_map)? }
          end
        end
      end
    RBS
  end

  def test_message_with_foreign_renamed_package
    input = read_protos(
      "foo.proto" => <<~PROTO,
        syntax = "proto3";

        package foo;

        option ruby_package = "FooPb";

        message Foo {
        }
      PROTO
      "bar.proto" => <<~PROTO,
        syntax = "proto3";

        import "foo.proto";

        message Bar {
          foo.Foo foo = 1;
        }
      PROTO
    )

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    translator.generate_rbs!

    file = translator.response.file.find { |file| file.name == "bar.rbs" }
    assert_equal <<~RBS, file.content
      class Bar < ::Google::Protobuf::AbstractMessage
        attr_accessor foo(): ::FooPb::Foo?

        def has_foo?: () -> bool

        def clear_foo: () -> void

        def initialize: (?foo: (::FooPb::Foo | ::FooPb::Foo::init_map)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: (\"foo\") -> ::FooPb::Foo?
              | (::String) -> untyped

        def []=: (\"foo\", ::FooPb::Foo?) -> void
               | (::String, untyped) -> void

        type init_map = { foo: (::FooPb::Foo | ::FooPb::Foo::init_map)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: false,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class ::Foo::BaR::Message < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end
    RBS
  end

  def test_message_with_one_of
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        oneof test_one_of {
          string name = 1;
          int32 size = 2;
        }
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_reader name(): ::String

        attr_writer name(): (::String | ::Symbol)?

        def has_name?: () -> bool

        def clear_name: () -> void

        attr_reader size(): ::Integer

        attr_writer size(): (::Integer | ::Float)?

        def has_size?: () -> bool

        def clear_size: () -> void

        attr_reader test_one_of(): (::String | ::Integer)?

        def clear_test_one_of: () -> void

        def initialize: (?name: (::String | ::Symbol)?, ?size: (::Integer | ::Float)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: (\"name\") -> ::String
              | (\"size\") -> ::Integer
              | (::String) -> untyped

        def []=: (\"name\", (::String | ::Symbol)?) -> void
               | (\"size\", (::Integer | ::Float)?) -> void
               | (::String, untyped) -> void

        type init_map = { name: (::String | ::Symbol)?, size: (::Integer | ::Float)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class Message < ::Google::Protobuf::AbstractMessage
        attr_accessor numbers(): ::Google::Protobuf::Map[::String, ::Integer, ::String | ::Symbol, ::Integer | ::Float]

        def clear_numbers: () -> void

        attr_accessor messages(): ::Google::Protobuf::Map[::Integer, ::Message, ::Integer | ::Float, ::Message]

        def clear_messages: () -> void

        def initialize: (?numbers: ::Hash[::String, ::Integer]?, ?messages: ::Hash[::Integer, ::Message]?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("numbers") -> ::Google::Protobuf::Map[::String, ::Integer, ::String | ::Symbol, ::Integer | ::Float]
              | ("messages") -> ::Google::Protobuf::Map[::Integer, ::Message, ::Integer | ::Float, ::Message]
              | (::String) -> untyped

        def []=: ("numbers", ::Google::Protobuf::Map[::String, ::Integer, ::String | ::Symbol, ::Integer | ::Float]) -> void
               | ("messages", ::Google::Protobuf::Map[::Integer, ::Message, ::Integer | ::Float, ::Message]) -> void
               | (::String, untyped) -> void

        type init_map = { numbers: ::Hash[::String, ::Integer]?, messages: ::Hash[::Integer, ::Message]? }
      end
    RBS
  end

  def test_message_with_map_to_enum
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Foo
        attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

        def self.lookup: (0 number) -> :bar
                       | (1 number) -> :baz
                       | (::int number) -> names?

        def self.resolve: (:bar name) -> 0
                        | (:baz name) -> 1
                        | (::Symbol name) -> numbers?

        type names = :bar | :baz

        type strings = "bar" | "baz"

        type numbers = 0 | 1
      end

      class Message < ::Google::Protobuf::AbstractMessage
        attr_accessor foos(): ::Google::Protobuf::Map[::String, ::Foo::names | ::Integer, ::String | ::Symbol, ::Foo::names | ::Foo::strings | ::Integer | ::Float]

        def clear_foos: () -> void

        def initialize: (?foos: ::Hash[::String, ::Foo::names | ::Integer]?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("foos") -> ::Google::Protobuf::Map[::String, ::Foo::names | ::Integer, ::String | ::Symbol, ::Foo::names | ::Foo::strings | ::Integer | ::Float]
              | (::String) -> untyped

        def []=: ("foos", ::Google::Protobuf::Map[::String, ::Foo::names | ::Integer, ::String | ::Symbol, ::Foo::names | ::Foo::strings | ::Integer | ::Float]) -> void
               | (::String, untyped) -> void

        type init_map = { foos: ::Hash[::String, ::Foo::names | ::Integer]? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Test1
        class Message < ::Google::Protobuf::AbstractMessage
          class Message2 < ::Google::Protobuf::AbstractMessage
            attr_accessor foo(): ::Google::Protobuf::Map[::String, ::String, ::String | ::Symbol, ::String | ::Symbol]

            def clear_foo: () -> void

            def initialize: (?foo: ::Hash[::String, ::String]?) -> void
                          | (::Hash[::Symbol | ::String, untyped] attributes) -> void

            def []: (\"foo\") -> ::Google::Protobuf::Map[::String, ::String, ::String | ::Symbol, ::String | ::Symbol]
                  | (::String) -> untyped

            def []=: (\"foo\", ::Google::Protobuf::Map[::String, ::String, ::String | ::Symbol, ::String | ::Symbol]) -> void
                   | (::String, untyped) -> void

            type init_map = { foo: ::Hash[::String, ::String]? }
          end

          def initialize: () -> void

          type init_map = { }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class M1 < ::Google::Protobuf::AbstractMessage
        class M2 < ::Google::Protobuf::AbstractMessage
          def initialize: () -> void

          type init_map = { }
        end

        attr_accessor m(): ::M1::M2?

        def has_m?: () -> bool

        def clear_m: () -> void

        def initialize: (?m: (::M1::M2 | ::M1::M2::init_map)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("m") -> ::M1::M2?
              | (::String) -> untyped

        def []=: ("m", ::M1::M2?) -> void
               | (::String, untyped) -> void

        type init_map = { m: (::M1::M2 | ::M1::M2::init_map)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~'RBS', content
      class Account < ::Google::Protobuf::AbstractMessage
        module Type
          Human: 0

          Bot: 1

          attr_reader self.descriptor: ::Google::Protobuf::EnumDescriptor

          def self.lookup: (0 number) -> :Human
                         | (1 number) -> :Bot
                         | (::int number) -> names?

          def self.resolve: (:Human name) -> 0
                          | (:Bot name) -> 1
                          | (::Symbol name) -> numbers?

          type names = :Human | :Bot

          type strings = "Human" | "Bot"

          type numbers = 0 | 1
        end

        attr_reader type(): ::Account::Type::names | ::Integer

        attr_writer type(): ::Account::Type::names | ::Account::Type::strings | ::Integer | ::Float

        attr_reader type_const(): ::Integer

        def has_type?: () -> bool

        def clear_type: () -> void

        def initialize: (?type: (::Account::Type::names | ::Account::Type::strings | ::Integer | ::Float)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: ("type") -> (::Account::Type::names | ::Integer)
              | (::String) -> untyped

        def []=: ("type", ::Account::Type::names | ::Account::Type::strings | ::Integer | ::Float) -> void
               | (::String, untyped) -> void

        type init_map = { type: (::Account::Type::names | ::Account::Type::strings | ::Integer | ::Float)? }
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

        rpc SampleClientStreamer(stream Message) returns (Message);
        rpc SampleServerStreamer(Message) returns (stream Message);
        rpc SampleBidiStreamer(stream Message) returns (stream Message);
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      class SearchRequest < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      class SearchResponse < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      class Message < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      module SearchService
        class Service
          include ::GRPC::GenericService

          def search: (::SearchRequest req, ::GRPC::ActiveCall::SingleReqView view) -> ::SearchResponse

          def send_message: (::Message req, ::GRPC::ActiveCall::SingleReqView view) -> ::Message

          def sample_client_streamer: (::GRPC::ActiveCall::MultiReqView[::Message] view) -> ::Message

          def sample_server_streamer: (::Message req, ::GRPC::ActiveCall::SingleReqView view) -> ::_Each[::Message]

          def sample_bidi_streamer: (::Enumerator[::Message, void] reqs, ::GRPC::ActiveCall::MultiReqView[void] view) -> ::_Each[::Message]
        end

        class Stub < ::GRPC::ClientStub
          def search: (::SearchRequest req, ?return_op: false, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::SearchResponse
                    | (::SearchRequest req, return_op: true, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::GRPC::ActiveCall::Operation[::SearchResponse]

          def send_message: (::Message req, ?return_op: false, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::Message
                          | (::Message req, return_op: true, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::GRPC::ActiveCall::Operation[::Message]

          def sample_client_streamer: (::_Each[::Message] reqs, ?return_op: false, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::Message
                                    | (::_Each[::Message] reqs, return_op: true, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::GRPC::ActiveCall::Operation[::Message]

          def sample_server_streamer: (::Message req, ?return_op: false, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::Enumerator[::Message, void]
                                    | (::Message req, return_op: true, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::GRPC::ActiveCall::Operation[::Enumerator[::Message, void]]
                                    | (::Message req, ?return_op: false, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) { (::Message res) -> void } -> void
                                    | (::Message req, return_op: true, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) { (::Message res) -> void } -> ::GRPC::ActiveCall::Operation[void]

          def sample_bidi_streamer: (::_Each[::Message] reqs, ?return_op: false, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::Enumerator[::Message, void]
                                  | (::_Each[::Message] reqs, return_op: true, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) -> ::GRPC::ActiveCall::Operation[::Enumerator[::Message, void]]
                                  | (::_Each[::Message] reqs, ?return_op: false, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) { (::Message res) -> void } -> void
                                  | (::_Each[::Message] reqs, return_op: true, ?deadline: ::Time?, ?parent: ::GRPC::Core::Call?, ?credentials: ::GRPC::Core::CallCredentials?, ?metadata: ::Hash[::String, ::String]) { (::Message res) -> void } -> ::GRPC::ActiveCall::Operation[void]
        end
      end
    RBS
  end

  # Extensions are not implemented in google-protobuf gem.
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
    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      module Test
        class M1 < ::Google::Protobuf::AbstractMessage
          def initialize: () -> void

          type init_map = { }
        end
      end
    RBS
  end

  def test_message_with_options
    input = read_proto(<<~EOP)
      syntax = "proto2";

      message Message {
        option deprecated = true;
        optional string name = 1 [deprecated = true];
      }
    EOP

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      nested_namespace: true,
    )
    content = translator.format_rbs(decls: translator.rbs_content(input.proto_file[0]))

    assert_equal <<~RBS, content
      # Protobuf options:
      #
      # - `deprecated = true`
      #
      class Message < ::Google::Protobuf::AbstractMessage
        # Protobuf options:
        #
        # - `deprecated = true`
        #
        attr_reader name(): ::String

        attr_writer name(): ::String | ::Symbol

        def has_name?: () -> bool

        def clear_name: () -> void

        def initialize: (?name: (::String | ::Symbol)?) -> void
                      | (::Hash[::Symbol | ::String, untyped] attributes) -> void

        def []: (\"name\") -> ::String
              | (::String) -> untyped

        def []=: (\"name\", ::String | ::Symbol) -> void
               | (::String, untyped) -> void

        type init_map = { name: (::String | ::Symbol)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      filters,
      nested_namespace: true,
    )
    translator.generate_rbs!

    output = translator.response.file.find {|file| file.name == "hello.rbs" }

    assert_equal <<~RBS, output.content
      module OuterNamespace
        class Foo < ::Google::Protobuf::AbstractMessage
          attr_reader bar(): ::String

          attr_writer bar(): ::String | ::Symbol

          def clear_bar: () -> void

          attr_reader baz(): ::String

          attr_writer baz(): ::String | ::Symbol

          def has_baz?: () -> bool

          def clear_baz: () -> void

          attr_reader _baz(): ::String?

          def clear__baz: () -> void

          def initialize: (?bar: (::String | ::Symbol)?, ?baz: (::String | ::Symbol)?) -> void
                        | (::Hash[::Symbol | ::String, untyped] attributes) -> void

          def []: (\"bar\") -> ::String
                | (\"baz\") -> ::String
                | (::String) -> untyped

          def []=: (\"bar\", ::String | ::Symbol) -> void
                 | (\"baz\", ::String | ::Symbol) -> void
                 | (::String, untyped) -> void

          type init_map = { bar: (::String | ::Symbol)?, baz: (::String | ::Symbol)? }
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      filters,
      nested_namespace: true,
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

    translator = RBSProtobuf::Translator::GoogleProtobufGem.new(
      input,
      [],
      nested_namespace: true,
    )
    translator.rbs_concat_level = 1
    translator.generate_rbs!

    assert translator.response.file.find {|file| file.name == "foo.rbs" }
    refute translator.response.file.find {|file| file.name == "foo/bar.rbs" }

    file = translator.response.file.find {|file| file.name == "foo.rbs" }
    assert_equal <<~RBS, file.content
      class Foo < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end

      class Bar < ::Google::Protobuf::AbstractMessage
        def initialize: () -> void

        type init_map = { }
      end
    RBS
  end
end
