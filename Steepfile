D = Steep::Diagnostic

target :lib do
  signature "sig"
  check "lib"

  configure_code_diagnostics do |hash|
    hash[D::Ruby::FallbackAny] = :hint
    hash[D::Ruby::MethodDefinitionMissing] = :hint
  end
end
