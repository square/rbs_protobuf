require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.warning = false
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => [:test, "example:typecheck"]

namespace :example do
  desc "Generate Ruby code with protobuf-gem"
  task :protobufgem do
    sh("rm -rf example/protobuf-gem")
    sh("mkdir", "-p", "example/protobuf-gem")
    sh(
      { "PB_NO_TAG_WARNINGS" => "1" },
      "protoc",
      "--plugin=protoc-gen-ruby-protobuf=#{__dir__}/bin/protoc-gen-ruby",
      "--ruby-protobuf_out=example/protobuf-gem",
      "-Iexample",
      "example/a.proto",
      "example/b.proto"
    )
    sh(
      { "RBS_PROTOBUF_BACKEND" => "protobuf" },
      "protoc",
      "--rbs_out=example/protobuf-gem",
      "-Iexample",
      "example/a.proto",
      "example/b.proto"
    )
  end

  desc "Type check generated code"
  task :typecheck => ["example:protobufgem"] do
    Dir.chdir "example" do
      sh(*%w(steep check))
    end
  end
end
