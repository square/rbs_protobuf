D = Steep::Diagnostic

target :lib do
  signature "sig"
  signature "vendor/gem_rbs_collection/gems/protobuf"
  check "lib"

  configure_code_diagnostics do |hash|
    hash[D::Ruby::FallbackAny] = :hint
    hash[D::Ruby::MethodDefinitionMissing] = :hint
    hash[D::Ruby::UnknownConstant] = :information
  end
end
