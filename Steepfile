D = Steep::Diagnostic

target :lib do
  signature "sig"
  check "lib"

  library "rbs"
  library "monitor"
  library "logger"
  library "set"
  library "json"
  library "tsort"
  library "pathname"
  library "optparse"
  library "rubygems"

  configure_code_diagnostics do |hash|
    hash[D::Ruby::FallbackAny] = :hint
    hash[D::Ruby::MethodDefinitionMissing] = :hint
  end
end
