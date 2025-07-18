/-
Test Suite: Comprehensive testing for post-incident-proofs system
Copyright (c) 2024 Post-Incident-Proofs Contributors

This module provides comprehensive tests for all core components including
logging, rate limiting, version control, dashboard generation, and bundle creation.
-/

import PostIncidentProofs.Logging.Core
import PostIncidentProofs.Logging.Verification
import PostIncidentProofs.Rate.Model
import PostIncidentProofs.Rate.Verification
import PostIncidentProofs.Version.Diff
import PostIncidentProofs.Dashboard.Generator
import PostIncidentProofs.Bundle.Builder
import PostIncidentProofs.Utils.Crypto
import PostIncidentProofs.Utils.Time

/-!
# Test Suite

This module provides comprehensive tests for the post-incident-proofs system,
validating all core components and their formal properties.

## Test Categories

- **Logging Tests**: Tamper-evident chain verification
- **Rate Limiting Tests**: Sliding window algorithm validation
- **Version Control Tests**: Diff/patch invertibility
- **Dashboard Tests**: Auto-generated Grafana dashboards
- **Bundle Tests**: Incident bundle integrity
- **Performance Tests**: Throughput and latency benchmarks
-/

/-- Test result -/
inductive TestResult where
  | Pass : String → TestResult
  | Fail : String → TestResult
  | Skip : String → TestResult
  deriving Repr

/-- Test suite result -/
structure TestSuiteResult where
  /-- Test name -/
  name : String
  /-- Test results -/
  results : List TestResult
  /-- Total tests -/
  total : UInt64
  /-- Passed tests -/
  passed : UInt64
  /-- Failed tests -/
  failed : UInt64
  /-- Skipped tests -/
  skipped : UInt64
  deriving Repr

/-!
## Logging Tests

Tests for tamper-evident logging chain functionality.
-/

/-- Test log entry creation and HMAC verification -/
def test_log_entry_hmac : TestResult :=
  let key := Crypto.generate_hmac_key
  let entry := Logging.LogEntry.mk' 1234567890 Logging.LogLevel.INFO "Test message" 42
  let entry_with_hmac := { entry with hmac := entry.compute_hmac key }

  if entry_with_hmac.verify_hmac key then
    TestResult.Pass "Log entry HMAC verification"
  else
    TestResult.Fail "Log entry HMAC verification failed"

/-- Test log chain counter monotonicity -/
def test_log_chain_counters : TestResult :=
  let key := Crypto.generate_hmac_key
  let entry1 := Logging.LogEntry.mk' 1234567890 Logging.LogLevel.INFO "First message" 1
  let entry2 := Logging.LogEntry.mk' 1234567891 Logging.LogLevel.INFO "Second message" 2
  let entry3 := Logging.LogEntry.mk' 1234567892 Logging.LogLevel.INFO "Third message" 3

  let chain := [
    { entry1 with hmac := entry1.compute_hmac key },
    { entry2 with hmac := entry2.compute_hmac key },
    { entry3 with hmac := entry3.compute_hmac key }
  ]

  if Logging.Verification.verify_chain_counters chain then
    TestResult.Pass "Log chain counter monotonicity"
  else
    TestResult.Fail "Log chain counter monotonicity failed"

/-- Test tamper detection -/
def test_tamper_detection : TestResult :=
  let key := Crypto.generate_hmac_key
  let entry1 := Logging.LogEntry.mk' 1234567890 Logging.LogLevel.INFO "First message" 1
  let entry2 := Logging.LogEntry.mk' 1234567891 Logging.LogLevel.INFO "Second message" 2

  let valid_chain := [
    { entry1 with hmac := entry1.compute_hmac key },
    { entry2 with hmac := entry2.compute_hmac key }
  ]

  let tampered_chain := [
    { entry1 with hmac := entry1.compute_hmac key },
    { entry2 with hmac := ByteArray.empty }  -- Tampered HMAC
  ]

  let valid_result := Logging.Verification.verify_chain valid_chain key
  let tampered_result := Logging.Verification.verify_chain tampered_chain key

  if valid_result == Logging.Verification.VerificationResult.Valid &&
     tampered_result != Logging.Verification.VerificationResult.Valid then
    TestResult.Pass "Tamper detection"
  else
    TestResult.Fail "Tamper detection failed"

/-!
## Rate Limiting Tests

Tests for sliding window rate limiting algorithm.
-/

/-- Test rate limit state creation -/
def test_rate_limit_creation : TestResult :=
  let config := Rate.RateLimitConfig.mk 100 60 "test-tenant"
  let state := Rate.RateLimitState.new config

  if state.current_count == 0 && state.window.isEmpty then
    TestResult.Pass "Rate limit state creation"
  else
    TestResult.Fail "Rate limit state creation failed"

/-- Test rate limit enforcement -/
def test_rate_limit_enforcement : TestResult :=
  let config := Rate.RateLimitConfig.mk 10 60 "test-tenant"
  let state := Rate.RateLimitState.new config
  let current_time : UInt64 := 1000

  -- Add requests up to limit
  let state' := state.add_request current_time 10
  let decision := state'.check_request current_time

  if decision == Rate.RateLimitDecision.Deny then
    TestResult.Pass "Rate limit enforcement"
  else
    TestResult.Fail "Rate limit enforcement failed"

/-- Test rate limit window cleanup -/
def test_rate_limit_cleanup : TestResult :=
  let config := Rate.RateLimitConfig.mk 10 60 "test-tenant"
  let state := Rate.RateLimitState.new config
  let old_time : UInt64 := 1000
  let new_time : UInt64 := 1070  -- 70 seconds later

  let state' := state.add_request old_time 5
  let state'' := state'.cleanup_window new_time

  if state''.current_count == 0 then
    TestResult.Pass "Rate limit window cleanup"
  else
    TestResult.Fail "Rate limit window cleanup failed"

/-- Test rate limit algorithm correctness -/
def test_rate_limit_correctness : TestResult :=
  let config := Rate.RateLimitConfig.mk 100 60 "test-tenant"
  let correctness := Rate.Verification.verify_algorithm_correctness config

  if correctness then
    TestResult.Pass "Rate limit algorithm correctness"
  else
    TestResult.Fail "Rate limit algorithm correctness failed"

/-!
## Version Control Tests

Tests for diff/patch invertibility.
-/

/-- Test state creation and verification -/
def test_version_state : TestResult :=
  let content := "test content".toUTF8
  let metadata := [("version", "1.0")]
  let state := Version.State.new "test-state" content metadata

  if state.verify then
    TestResult.Pass "Version state creation and verification"
  else
    TestResult.Fail "Version state creation and verification failed"

/-- Test diff application and revert -/
def test_diff_invertibility : TestResult :=
  let original_content := "original content".toUTF8
  let new_content := "new content".toUTF8
  let state := Version.State.new "test-state" original_content []
  let diff := Version.Diff.Mod "test-state" new_content

  let state_after_apply := Version.apply_diff state diff
  let state_after_revert := Version.revert_diff state_after_apply diff

  if state_after_revert.content == state.content then
    TestResult.Pass "Diff invertibility"
  else
    TestResult.Fail "Diff invertibility failed"

/-- Test stress test invertibility -/
def test_stress_invertibility : TestResult :=
  let content := "stress test content".toUTF8
  let state := Version.State.new "stress-test" content []
  let diffs := Version.generate_random_diffs state 5
  let cycles : UInt64 := 100  -- Reduced for testing

  let result := Version.stress_test_invertibility state diffs cycles

  if result then
    TestResult.Pass "Stress test invertibility"
  else
    TestResult.Fail "Stress test invertibility failed"

/-!
## Dashboard Tests

Tests for auto-generated Grafana dashboards.
-/

/-- Test dashboard specification creation -/
def test_dashboard_spec : TestResult :=
  let spec := Dashboard.log_tamper_spec

  if spec.name == "log_tamper_detection" && spec.threshold == 0.0 then
    TestResult.Pass "Dashboard specification creation"
  else
    TestResult.Fail "Dashboard specification creation failed"

/-- Test dashboard generation -/
def test_dashboard_generation : TestResult :=
  let specs := [Dashboard.log_tamper_spec, Dashboard.rate_limit_spec]
  let dashboard := Dashboard.generate_dashboard specs

  if dashboard.panels.length == 2 then
    TestResult.Pass "Dashboard generation"
  else
    TestResult.Fail "Dashboard generation failed"

/-- Test alert rule generation -/
def test_alert_rule_generation : TestResult :=
  let specs := [Dashboard.log_tamper_spec]
  let rules := Dashboard.generate_alert_rules specs

  if rules.length == 1 then
    TestResult.Pass "Alert rule generation"
  else
    TestResult.Fail "Alert rule generation failed"

/-!
## Bundle Tests

Tests for incident bundle creation and validation.
-/

/-- Test bundle creation -/
def test_bundle_creation : TestResult :=
  let logs := []
  let specs := ["test_spec.lean"]
  let window := { start := 0, end := 86400 }
  let bundle := Bundle.Builder.create_bundle logs specs window

  if bundle.id.length > 0 && bundle.size_bytes > 0 then
    TestResult.Pass "Bundle creation"
  else
    TestResult.Fail "Bundle creation failed"

/-- Test bundle validation -/
def test_bundle_validation : TestResult :=
  let logs := []
  let specs := ["test_spec.lean"]
  let window := { start := 0, end := 86400 }
  let bundle := Bundle.Builder.create_bundle logs specs window
  let validation := Bundle.Builder.validate_bundle bundle

  match validation with
  | Bundle.Builder.ValidationResult.Valid => TestResult.Pass "Bundle validation"
  | _ => TestResult.Fail "Bundle validation failed"

/-- Test bundle size limit -/
def test_bundle_size_limit : TestResult :=
  let logs := []
  let specs := ["test_spec.lean"]
  let window := { start := 0, end := 86400 }
  let bundle := Bundle.Builder.create_bundle logs specs window

  if bundle.size_bytes <= 5 * 1024 * 1024 then  -- 5MB limit
    TestResult.Pass "Bundle size limit"
  else
    TestResult.Fail "Bundle size limit exceeded"

/-!
## Performance Tests

Tests for system performance and throughput.
-/

/-- Test log throughput benchmark -/
def test_log_throughput : TestResult :=
  let key := Crypto.generate_hmac_key
  let test_entries := List.range 1000 |>.map (fun i =>
    Logging.LogEntry.mk' (i.toUInt64) Logging.LogLevel.INFO s!"Message {i}" i.toUInt64)
  let chain := test_entries.map (fun entry => { entry with hmac := entry.compute_hmac key })

  let throughput := Logging.Verification.measure_throughput chain key

  if throughput >= 200000.0 then  -- 200k entries/s target
    TestResult.Pass s!"Log throughput: {throughput} entries/s"
  else
    TestResult.Fail s!"Log throughput below target: {throughput} entries/s"

/-- Test rate limit throughput -/
def test_rate_limit_throughput : TestResult :=
  let config := Rate.RateLimitConfig.mk 1000 60 "test-tenant"
  let throughput := Rate.Verification.measure_throughput config 10000

  if throughput >= 30000.0 then  -- 30k rps target
    TestResult.Pass s!"Rate limit throughput: {throughput} requests/s"
  else
    TestResult.Fail s!"Rate limit throughput below target: {throughput} requests/s"

/-!
## Test Suite Runner

Functions for running all tests and generating reports.
-/

/-- All test functions -/
def all_tests : List (String × (Unit → TestResult)) :=
  [
    ("Log Entry HMAC", fun _ => test_log_entry_hmac),
    ("Log Chain Counters", fun _ => test_log_chain_counters),
    ("Tamper Detection", fun _ => test_tamper_detection),
    ("Rate Limit Creation", fun _ => test_rate_limit_creation),
    ("Rate Limit Enforcement", fun _ => test_rate_limit_enforcement),
    ("Rate Limit Cleanup", fun _ => test_rate_limit_cleanup),
    ("Rate Limit Correctness", fun _ => test_rate_limit_correctness),
    ("Version State", fun _ => test_version_state),
    ("Diff Invertibility", fun _ => test_diff_invertibility),
    ("Stress Invertibility", fun _ => test_stress_invertibility),
    ("Dashboard Spec", fun _ => test_dashboard_spec),
    ("Dashboard Generation", fun _ => test_dashboard_generation),
    ("Alert Rule Generation", fun _ => test_alert_rule_generation),
    ("Bundle Creation", fun _ => test_bundle_creation),
    ("Bundle Validation", fun _ => test_bundle_validation),
    ("Bundle Size Limit", fun _ => test_bundle_size_limit),
    ("Log Throughput", fun _ => test_log_throughput),
    ("Rate Limit Throughput", fun _ => test_rate_limit_throughput)
  ]

/-- Run a single test -/
def run_test (name : String) (test : Unit → TestResult) : TestResult :=
  test ()

/-- Run all tests -/
def run_all_tests : TestSuiteResult :=
  let results := all_tests.map (fun (name, test) => (name, run_test name test))
  let test_results := results.map (fun (_, result) => result)

  let passed := test_results.filter (fun result => match result with | TestResult.Pass _ => true | _ => false) |>.length
  let failed := test_results.filter (fun result => match result with | TestResult.Fail _ => true | _ => false) |>.length
  let skipped := test_results.filter (fun result => match result with | TestResult.Skip _ => true | _ => false) |>.length

  {
    name := "Post-Incident-Proofs Test Suite"
    results := test_results
    total := all_tests.length.toUInt64
    passed := passed.toUInt64
    failed := failed.toUInt64
    skipped := skipped.toUInt64
  }

/-- Print test results -/
def print_test_results (results : TestSuiteResult) : IO Unit := do
  IO.println s!"\n{results.name}"
  IO.println "=" * 50
  IO.println s!"Total Tests: {results.total}"
  IO.println s!"Passed: {results.passed}"
  IO.println s!"Failed: {results.failed}"
  IO.println s!"Skipped: {results.skipped}"
  IO.println ""

  let test_names := all_tests.map (fun (name, _) => name)
  let zipped := test_names.zip results.results

  for (name, result) in zipped do
    match result with
    | TestResult.Pass msg => IO.println s!"✓ {name}: {msg}"
    | TestResult.Fail msg => IO.println s!"✗ {name}: {msg}"
    | TestResult.Skip msg => IO.println s!"- {name}: {msg} (skipped)"

/-- Main test runner -/
def main (args : List String) : IO UInt32 := do
  IO.println "Running Post-Incident-Proofs Test Suite..."

  let results := run_all_tests
  print_test_results results

  if results.failed == 0 then
    IO.println "\n🎉 All tests PASSED!"
    return 0
  else
    IO.println s!"\n❌ {results.failed} tests FAILED!"
    return 1
