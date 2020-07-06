require "test_helper"

class TranslatorTest < Minitest::Test
  include TestHelper

  def test_scalar_field
    input = read_proto(<<EOP)
syntax = "proto2";

message Message1 {
  optional string name = 1;
  required string login = 2;
  repeated string phone_number = 3;
}
EOP

    translator = RbsProtobuf::Translator.new(input)

    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
class Message1
  attr_accessor name(): ::String

  attr_accessor login(): ::String

  attr_accessor phone_number(): ::Array[::String]

  def initialize: (?name: ::String, ?login: ::String, ?phone_number: ::Array[::String]) -> void
end
RBS
  end

  def test_all_scalar_field
    input = read_proto(<<EOP)
syntax = "proto2";

message Message1 {
  optional double double_field = 1;
  optional float float_field = 2;
  optional int32 int32_field = 3;
  optional int64 int64_field = 4;
  optional uint32 uint32_field = 5;
  optional uint64 uint64_field = 6;
  optional sint32 sint32_field = 7;
  optional sint64 sint64_field = 8;
  optional fixed32 fixed32_field = 9;
  optional fixed64 fixed64_field = 10;
  optional sfixed32 sfixed32_field = 11;
  optional sfixed64 sfixed64_field = 12;
  optional bool bool_field = 13;
  optional string string_field = 14;
  optional bytes bytes_field = 15;
}
EOP

    translator = RbsProtobuf::Translator.new(input)

    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
class Message1
  attr_accessor double_field(): ::Float

  attr_accessor float_field(): ::Float

  attr_accessor int32_field(): ::Integer

  attr_accessor int64_field(): ::Integer

  attr_accessor uint32_field(): ::Integer

  attr_accessor uint64_field(): ::Integer

  attr_accessor sint32_field(): ::Integer

  attr_accessor sint64_field(): ::Integer

  attr_accessor fixed32_field(): ::Integer

  attr_accessor fixed64_field(): ::Integer

  attr_accessor sfixed32_field(): ::Integer

  attr_accessor sfixed64_field(): ::Integer

  attr_accessor bool_field(): ::TrueClass | ::FalseClass

  attr_accessor string_field(): ::String

  attr_accessor bytes_field(): ::String

  def initialize: (?double_field: ::Float, ?float_field: ::Float, ?int32_field: ::Integer, ?int64_field: ::Integer, ?uint32_field: ::Integer, ?uint64_field: ::Integer, ?sint32_field: ::Integer, ?sint64_field: ::Integer, ?fixed32_field: ::Integer, ?fixed64_field: ::Integer, ?sfixed32_field: ::Integer, ?sfixed64_field: ::Integer, ?bool_field: ::TrueClass | ::FalseClass, ?string_field: ::String, ?bytes_field: ::String) -> void
end
RBS
  end

  def test_enum
    input = read_proto(<<EOP)
syntax = "proto2";

message SearchRequest {
  enum Corpus {
    UNIVERSAL = 0;
    WEB = 1;
    IMAGES = 2;
    LOCAL = 3;
    NEWS = 4;
    PRODUCTS = 5;
    VIDEO = 6;
  }
  optional Corpus corpus = 4 [default = UNIVERSAL];
}
EOP

    translator = RbsProtobuf::Translator.new(input)

    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
class SearchRequest
  module Corpus
    type symbols = :UNIVERSAL | :WEB | :IMAGES | :LOCAL | :NEWS | :PRODUCTS | :VIDEO

    UNIVERSAL: ::Integer

    WEB: ::Integer

    IMAGES: ::Integer

    LOCAL: ::Integer

    NEWS: ::Integer

    PRODUCTS: ::Integer

    VIDEO: ::Integer

    def self.lookup: (::Integer number) -> symbols?

    def self.resolve: (::Symbol symbol) -> ::Integer?
  end

  attr_reader corpus(): ::SearchRequest::Corpus::symbols

  attr_writer corpus(): ::SearchRequest::Corpus::symbols | ::Integer

  def initialize: (?corpus: ::SearchRequest::Corpus::symbols | ::Integer) -> void
end
RBS
  end

  def test_toplevel_enum
    input = read_proto(<<EOP)
syntax = "proto2";

package foo;

enum Corpus {
  UNIVERSAL = 0;
  WEB = 1;
  IMAGES = 2;
  LOCAL = 3;
  NEWS = 4;
  PRODUCTS = 5;
  VIDEO = 6;
}
EOP

    translator = RbsProtobuf::Translator.new(input)

    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
module Foo::Corpus
  type symbols = :UNIVERSAL | :WEB | :IMAGES | :LOCAL | :NEWS | :PRODUCTS | :VIDEO

  UNIVERSAL: ::Integer

  WEB: ::Integer

  IMAGES: ::Integer

  LOCAL: ::Integer

  NEWS: ::Integer

  PRODUCTS: ::Integer

  VIDEO: ::Integer

  def self.lookup: (::Integer number) -> symbols?

  def self.resolve: (::Symbol symbol) -> ::Integer?
end
RBS
  end

  def test_message_toplevel
    input = read_proto(<<EOP)
syntax = "proto2";

message Result {
  required string url = 1;
  optional string title = 2;
  repeated string snippets = 3;
}

message SearchResponse {
  repeated Result result = 1;
}
EOP

    translator = RbsProtobuf::Translator.new(input)

    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
class Result
  attr_accessor url(): ::String

  attr_accessor title(): ::String

  attr_accessor snippets(): ::Array[::String]

  def initialize: (?url: ::String, ?title: ::String, ?snippets: ::Array[::String]) -> void
end

class SearchResponse
  attr_accessor result(): ::Array[::Result]

  def initialize: (?result: ::Array[::Result]) -> void
end
RBS
  end

  def test_message_nested
    input = read_proto(<<EOP)
syntax = "proto2";

message SearchResponse {
  repeated Result result = 1;

  message Result {
    required string url = 1;
    optional string title = 2;
    repeated string snippets = 3;
  }
}
EOP

    translator = RbsProtobuf::Translator.new(input)

    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
class SearchResponse
  class Result
    attr_accessor url(): ::String

    attr_accessor title(): ::String

    attr_accessor snippets(): ::Array[::String]

    def initialize: (?url: ::String, ?title: ::String, ?snippets: ::Array[::String]) -> void
  end

  attr_accessor result(): ::Array[::SearchResponse::Result]

  def initialize: (?result: ::Array[::SearchResponse::Result]) -> void
end
RBS
  end

  def test_oneof
    input = read_proto(<<EOP)
syntax = "proto2";

message SampleMessage {
  optional string hoge = 1;

  oneof test_oneof {
     string name = 8;
     string email = 9;
  }
}
EOP

    translator = RbsProtobuf::Translator.new(input)
    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
class SampleMessage
  attr_accessor hoge(): ::String

  attr_accessor name(): ::String

  attr_accessor email(): ::String

  def initialize: (?hoge: ::String, ?name: ::String, ?email: ::String) -> void

  def test_oneof: () -> (:name | :email)
end
RBS
  end

  def test_map
    input = read_proto(<<EOP)
syntax = "proto2";

message SampleMessage {
  map<string, Project> projects = 3;
}

message Project {
  required string name = 1;
}
EOP

    translator = RbsProtobuf::Translator.new(input)
    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
class SampleMessage
  attr_accessor projects(): ::Hash[::String, ::Project?]

  def initialize: (?projects: ::Hash[::String, ::Project?]) -> void
end

class Project
  attr_accessor name(): ::String

  def initialize: (?name: ::String) -> void
end
RBS
  end

  def test_package
    input = read_proto(<<EOP)
syntax = "proto2";

package foo.bar_baz;

message Open {
  required string timestamp = 1;
  optional Open next_open = 2;
}
EOP

    translator = RbsProtobuf::Translator.new(input)
    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<RBS, content
class Foo::BarBaz::Open
  attr_accessor timestamp(): ::String

  attr_accessor next_open(): ::Foo::BarBaz::Open?

  def initialize: (?timestamp: ::String, ?next_open: ::Foo::BarBaz::Open?) -> void
end
RBS
  end

  def test_comment
    input = read_proto(<<EOP)
syntax = "proto2";

/*
  Comment before E.
*/
enum E {
  /* Comment before E.FOO. */
  FOO = 1;
  BAR = 2;  /* Comment after E.BAR. */
}

/* Comment before M */
message M {
  optional string a = 1;   /* Comment after M.a */

  optional string b = 2;

  /* Comment before M.c */
  repeated int64 c = 3;

  /* Comment before M.F */
  enum F {
    X = 1;
  }

  /* Comment before M.N */
  message N {
    required string x = 1;
  }
}
EOP

    translator = RbsProtobuf::Translator.new(input)
    content = translator.response.file.find {|file| file.name == "./a_pb.rbs" }.content

    assert_equal <<EOF, content
# Comment before E.
module E
  type symbols = :FOO | :BAR

  # Comment before E.FOO.
  FOO: ::Integer

  # Comment after E.BAR.
  BAR: ::Integer

  def self.lookup: (::Integer number) -> symbols?

  def self.resolve: (::Symbol symbol) -> ::Integer?
end

# Comment before M
class M
  # Comment before M.F
  module F
    type symbols = :X

    X: ::Integer

    def self.lookup: (::Integer number) -> symbols?

    def self.resolve: (::Symbol symbol) -> ::Integer?
  end

  # Comment before M.N
  class N
    attr_accessor x(): ::String

    def initialize: (?x: ::String) -> void
  end

  # Comment after M.a
  attr_accessor a(): ::String

  attr_accessor b(): ::String

  # Comment before M.c
  attr_accessor c(): ::Array[::Integer]

  def initialize: (?a: ::String, ?b: ::String, ?c: ::Array[::Integer]) -> void
end
EOF
  end
end
