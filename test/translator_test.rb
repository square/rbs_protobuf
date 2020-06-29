require "test_helper"

class TranslatorTest < Minitest::Test
  include TestHelper

  def test_search_request
    input = read_code_generator_request("search_request.proto")

    translator = RbsProtobuf::Translator.new(input)
    res = translator.response

    files = res.file
    assert_equal 1, files.size

    puts files[0].content
  end
end
