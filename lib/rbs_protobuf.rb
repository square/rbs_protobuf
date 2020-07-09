require "rbs_protobuf/version"

require "logger"

require "protobuf/descriptors"
require "active_support/inflector"
require "rbs"

module RBSProtobuf
  class <<self
    attr_reader :logger
  end

  @logger = Logger.new(STDERR)
end

require "rbs_protobuf/rbs_factory"
require "rbs_protobuf/translator/base"
require "rbs_protobuf/translator/protobuf_gem"
