D = Steep::Diagnostic

target :lib do
  signature "sig"
  check "lib"

  configure_code_diagnostics do |hash|
    hash[D::Ruby::FallbackAny] = :hint
    hash[D::Ruby::MethodDefinitionMissing] = :hint
    hash[D::Ruby::UnknownConstant] = :information
  end
end
