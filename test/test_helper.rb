$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rbs_protobuf"

require "minitest/autorun"
require "tmpdir"
require "open3"

module TestHelper
  def read_code_generator_request(proto_path)
    full_path = File.join(__dir__, "../examples", proto_path)
    dumper_path = File.join(__dir__, "../bin/protoc-gen-dumper")

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Open3.capture2("protoc",
                       "--plugin=#{dumper_path}",
                       "--dumper_out=/",      # --dumper_out is ignored
                       "--proto_path=#{File.join(__dir__, "../examples")}",
                       full_path)
      end

      content = File.read(File.join(dir, "a.pb.out"))
      Google::Protobuf::Compiler::CodeGeneratorRequest.decode(content)
    end
  end

  def read_proto(proto)
    dumper_path = File.join(__dir__, "../bin/protoc-gen-dumper")

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "a.proto"), proto)

      Dir.chdir(dir) do
        Open3.capture2("protoc",
                       "--plugin=#{dumper_path}",
                       "--dumper_out=/",      # --dumper_out is ignored
                       "--proto_path=#{dir}",
                       "a.proto")
      end

      content = File.read(File.join(dir, "a.pb.out"))
      Google::Protobuf::Compiler::CodeGeneratorRequest.decode(content)
    end
  end
end
