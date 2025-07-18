/-
Security Testing Executable
===========================

This executable runs comprehensive security tests and threat modeling
for the post-incident-proofs system.
-/

import PostIncidentProofs.Security.ThreatModel
import PostIncidentProofs.Benchmark.Performance
import PostIncidentProofs.Chaos.Engine

def main : IO Unit := do
  IO.println "🔒 Post-Incident-Proofs Security Testing"
  IO.println "=" * 50

  -- Run security tests
  IO.println "\n1. Running Security Tests..."
  let security_metrics ← PostIncidentProofs.Security.ThreatModel.runSecurityTests

  IO.println s!"   Tamper Detection Time: {security_metrics.tamper_detection_time}"
  IO.println s!"   Rate Limit False Positives: {security_metrics.rate_limit_false_positives * 100:.3f}%"
  IO.println s!"   Rate Limit False Negatives: {security_metrics.rate_limit_false_negatives * 100:.3f}%"
  IO.println s!"   Chain Verification Time: {security_metrics.chain_verification_time}"
  IO.println s!"   Proof Storage Overhead: {security_metrics.proof_storage_overhead * 100:.1f}%"

  -- Validate security properties
  IO.println "\n2. Validating Security Properties..."
  let security_valid ← PostIncidentProofs.validate_security_properties
  IO.println s!"   Security Properties: {if security_valid then \"✅ PASS\" else \"❌ FAIL\"}"

  -- Run performance benchmarks
  IO.println "\n3. Running Performance Benchmarks..."
  let performance_results ← PostIncidentProofs.Benchmark.Performance.runAllBenchmarks

  for result in performance_results do
    let status := if result.success then "✅ PASS" else "❌ FAIL"
    IO.println s!"   {result.test_name}: {status}"
    IO.println s!"     Duration: {result.duration}"
    IO.println s!"     Throughput: {result.throughput:.2f}/sec"
    IO.println s!"     Memory: {result.memory_usage} bytes"
    IO.println s!"     CPU: {result.cpu_usage * 100:.1f}%"

  -- Run chaos tests
  IO.println "\n4. Running Chaos Engineering Tests..."
  let chaos_config := { PostIncidentProofs.Chaos.Engine.ChaosConfig. }
  let chaos_results ← PostIncidentProofs.Chaos.Engine.runChaosTestSuite chaos_config

  for result in chaos_results do
    let status := if result.success then "✅ PASS" else "❌ FAIL"
    IO.println s!"   {result.scenario}: {status}"
    IO.println s!"     Duration: {result.duration}"
    IO.println s!"     Errors: {result.error_count}"
    IO.println s!"     Performance Impact: {result.performance_degradation * 100:.1f}%"
    IO.println s!"     Data Integrity: {if result.data_integrity_maintained then \"✅\" else \"❌\"}"
    IO.println s!"     Recovery Time: {result.recovery_time}"

  -- Generate security report
  IO.println "\n5. Generating Security Report..."
  let total_tests := performance_results.length + chaos_results.length
  let passed_tests := (performance_results.filter (·.success) |>.length) +
                     (chaos_results.filter (·.success) |>.length)
  let success_rate := passed_tests.toFloat / total_tests.toFloat * 100

  IO.println s!"\n📊 Security Test Summary:"
  IO.println s!"   Total Tests: {total_tests}"
  IO.println s!"   Passed: {passed_tests}"
  IO.println s!"   Failed: {total_tests - passed_tests}"
  IO.println s!"   Success Rate: {success_rate:.1f}%"

  if success_rate >= 90.0 then
    IO.println "\n✅ Security validation PASSED"
    IO.exit 0
  else
    IO.println "\n❌ Security validation FAILED"
    IO.exit 1
