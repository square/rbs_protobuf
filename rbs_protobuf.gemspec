require_relative 'lib/rbs_protobuf/version'

Gem::Specification.new do |spec|
  spec.name          = "rbs_protobuf"
  spec.version       = RBSProtobuf::VERSION
  spec.authors       = ["Soutaro Matsumoto"]
  spec.email         = ["matsumoto@soutaro.com"]

  spec.summary       = "Generate RBS files from .proto files"
  spec.description   = "Generate RBS files from .proto files"
  spec.homepage      = "https://github.com/square/rbs_protobuf"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/square/rbs_protobuf"
  spec.metadata["changelog_uri"] = "https://github.com/square/rbs_protobuf/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rbs", ">=2.2.0"
  spec.add_runtime_dependency "activesupport", ">=4.0"
end
