import Lake
open Lake DSL

package post-incident-proofs {
  -- add package configuration options here
  srcDir := "src"
  -- dependencies
  require lean from git "https://github.com/leanprover/lean4.git" @ "v4.7.0"
  require runtime-safety-kernels from git "https://github.com/runtime-safety/runtime-safety-kernels.git" @ "main"
  require security-envelopes from git "https://github.com/security-envelopes/security-envelopes.git" @ "main"
}

@[default_target]
lean_lib PostIncidentProofs {
  roots := #[`PostIncidentProofs]
}

-- Executable for bundle verification
lean_exe verify_bundle {
  root := `VerifyBundle
}

-- Executable for log chain verification
lean_exe log_verifier {
  root := `LogVerifier
}

-- Executable for rate limit verification
lean_exe rate_verifier {
  root := `RateVerifier
}

-- Executable for version diff verification
lean_exe version_verifier {
  root := `VersionVerifier
}

-- Test suite
lean_exe tests {
  root := `Tests
}

-- Benchmark suite
lean_exe benchmarks {
  root := `Benchmarks
}

-- Security testing
lean_exe security {
  root := `Security
}

-- Observability testing
lean_exe observability {
  root := `Observability
}

-- Comprehensive validation
lean_exe validate {
  root := `Validate
}
