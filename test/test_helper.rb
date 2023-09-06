require "bundler/setup"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rbs_protobuf"

require "minitest/autorun"
require "tmpdir"
require "open3"

module TestHelper
  def tmpdir_path
    Pathname(File.join(__dir__, "../tmp")).cleanpath.to_s
  end

  def setup
    super
    Dir.mkdir(tmpdir_path) unless Dir.exist?(tmpdir_path)
  end

  def read_proto(proto)
    read_protos("a.proto" => proto)
  end

  def read_protos(protos)
    dumper_path = File.join(__dir__, "../bin/protoc-gen-dumper")

    Dir.mktmpdir(nil, tmpdir_path) do |dir|
      protos.each do |name, content|
        path = Pathname(dir) + name
        path.parent.mkpath
        path.write(content)
      end

      Dir.chdir(dir) do
        Open3.capture2(
          "protoc",
          "--plugin=#{dumper_path}",
          "--dumper_out=/",      # --dumper_out is ignored
          "--proto_path=#{dir}",
          *protos.keys
        )
      end

      content = File.read(File.join(dir, "a.pb.out"))
      Google::Protobuf::Compiler::CodeGeneratorRequest.decode(content)
    end
  end
end
