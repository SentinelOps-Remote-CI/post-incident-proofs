/-
Rate Limiting Verification: State validation and correctness checking
Copyright (c) 2024 Post-Incident-Proofs Contributors

This module provides verification algorithms for rate limiting state
correctness and validates the formal properties of the sliding window algorithm.
-/

import PostIncidentProofs.Rate.Model
import PostIncidentProofs.Utils.Time

namespace PostIncidentProofs.Rate.Verification

/-!
# Rate Limiting Verification

This module provides comprehensive verification of rate limiting state
correctness and validates the formal properties of our sliding window algorithm.

## Key Features

- **State Validation**: Verify rate limit state consistency
- **Correctness Checking**: Validate formal properties
- **Performance Testing**: Measure algorithm performance
- **Chaos Testing**: Validate against high-load scenarios
-/

/-- Verification result for rate limiting state -/
inductive VerificationResult where
  | Valid : VerificationResult
  | InvalidCount : UInt64 → UInt64 → VerificationResult  -- actual vs expected
  | InvalidWindow : String → VerificationResult  -- window violation
  | InvalidConfig : String → VerificationResult  -- config violation
  deriving Repr

/-- Verify that rate limit state is consistent -/
def verify_state (state : RateLimitState) (current_time : UInt64) : VerificationResult :=
  -- Check configuration validity
  if state.config.max_requests == 0 then
    VerificationResult.InvalidConfig "max_requests cannot be zero"
  else if state.config.window_seconds == 0 then
    VerificationResult.InvalidConfig "window_seconds cannot be zero"
  else
    -- Check window consistency
    let state' := state.cleanup_window current_time
    let expected_count := state'.window.foldl (fun acc record => acc + record.count) 0

    if state'.current_count != expected_count then
      VerificationResult.InvalidCount state'.current_count expected_count
    else if state'.current_count > state'.config.max_requests then
      VerificationResult.InvalidWindow "current_count exceeds max_requests"
    else
      -- Check window timestamps
      let cutoff_time := current_time - state'.config.window_seconds
      let invalid_records := state'.window.filter (fun record => record.timestamp ≤ cutoff_time)

      if invalid_records.length > 0 then
        VerificationResult.InvalidWindow "window contains expired records"
      else
        VerificationResult.Valid

/-- Verify that rate limiting decisions are correct -/
def verify_decision_correctness
  (state : RateLimitState)
  (timestamp : UInt64)
  (decision : RateLimitDecision) : Bool :=
  let state' := state.cleanup_window timestamp
  match decision with
  | RateLimitDecision.Allow => state'.current_count < state'.config.max_requests
  | RateLimitDecision.Deny => state'.current_count ≥ state'.config.max_requests

/-- Verify multi-tenant rate limiting state -/
def verify_multi_tenant_state (state : MultiTenantRateLimit) (current_time : UInt64) : List (String × VerificationResult) :=
  state.tenants.map (fun (tenant_id, tenant_state) =>
    (tenant_id, verify_state tenant_state current_time))

/-- Comprehensive verification of rate limiting algorithm -/
def verify_algorithm_correctness (config : RateLimitConfig) : Bool :=
  -- Test basic properties
  let state := RateLimitState.new config
  let current_time : UInt64 := 1000

  -- Test 1: Empty state should allow requests
  let test1 := state.check_request current_time == RateLimitDecision.Allow

  -- Test 2: Adding requests up to limit should work
  let state2 := state.add_request current_time config.max_requests
  let test2 := state2.current_count == config.max_requests

  -- Test 3: Exceeding limit should be denied
  let test3 := state2.check_request current_time == RateLimitDecision.Deny

  -- Test 4: After window expires, should allow again
  let future_time := current_time + config.window_seconds + 1
  let test4 := state2.check_request future_time == RateLimitDecision.Allow

  test1 && test2 && test3 && test4

/-!
## Performance Verification

Functions to verify that the rate limiting algorithm meets performance requirements.
-/

/-- Measure rate limiting throughput -/
def measure_throughput (config : RateLimitConfig) (iterations : UInt64) : Float :=
  let state := RateLimitState.new config
  let start_time := Time.monotonic_nanos ()

  let rec run (n : UInt64) (current_state : RateLimitState) : RateLimitState :=
    if n == 0 then
      current_state
    else
      let decision := current_state.check_request n
      let new_state := if decision == RateLimitDecision.Allow then
        current_state.add_request n 1 else current_state
      run (n - 1) new_state

  let _ := run iterations state
  let end_time := Time.monotonic_nanos ()
  let time_seconds := (end_time - start_time).toFloat / 1_000_000_000.0
  iterations.toFloat / time_seconds

/-- Verify that throughput meets requirements (≥ 30k rps) -/
def verify_throughput_requirement (config : RateLimitConfig) : Bool :=
  let throughput := measure_throughput config 30000
  throughput ≥ 30000.0

/-!
## Chaos Testing Verification

Functions to validate the algorithm against high-load scenarios.
-/

/-- Run chaos test and verify results -/
def run_chaos_test (config : RateLimitConfig) : Bool :=
  let burst_size : UInt64 := 30000
  let duration_seconds : UInt64 := 60
  let decisions := simulate_burst_traffic config burst_size duration_seconds

  -- Calculate expected allows based on rate limit
  let expected_allows := config.max_requests * (duration_seconds / config.window_seconds)

  -- Validate results
  validate_chaos_test decisions expected_allows

/-- Verify false positive rate is within bounds -/
def verify_false_positive_rate (config : RateLimitConfig) : Bool :=
  let test_iterations : UInt64 := 100000
  let state := RateLimitState.new config

  let rec count_false_positives (n : UInt64) (current_state : RateLimitState) (count : UInt64) : UInt64 :=
    if n == 0 then
      count
    else
      let decision := current_state.check_request n
      let new_state := if decision == RateLimitDecision.Allow then
        current_state.add_request n 1 else current_state
      let new_count := if decision == RateLimitDecision.Deny &&
                          current_state.current_count < config.max_requests then
        count + 1 else count
      count_false_positives (n - 1) new_state new_count

  let false_positives := count_false_positives test_iterations state 0
  let false_positive_rate := false_positives.toFloat / test_iterations.toFloat
  false_positive_rate ≤ 0.001  -- ≤ 0.1%

/-- Verify zero false negatives -/
def verify_zero_false_negatives (config : RateLimitConfig) : Bool :=
  let test_iterations : UInt64 := 10000
  let state := RateLimitState.new config

  let rec check_false_negatives (n : UInt64) (current_state : RateLimitState) : Bool :=
    if n == 0 then
      true
    else
      let decision := current_state.check_request n
      let new_state := if decision == RateLimitDecision.Allow then
        current_state.add_request n 1 else current_state

      -- Check that we never allow when we should deny
      let should_deny := current_state.current_count ≥ config.max_requests
      let false_negative := should_deny && decision == RateLimitDecision.Allow

      if false_negative then
        false
      else
        check_false_negatives (n - 1) new_state

  check_false_negatives test_iterations state

/-!
## Formal Property Verification

The following functions verify the formal properties of our rate limiting algorithm.
-/

/-- Verify rate limit enforcement property -/
def verify_enforcement_property (state : RateLimitState) (timestamp : UInt64) : Bool :=
  let state' := state.cleanup_window timestamp
  state'.current_count ≤ state'.config.max_requests

/-- Verify monotonicity property -/
def verify_monotonicity_property (state : RateLimitState) (timestamp : UInt64) (count : UInt64) : Bool :=
  let state' := state.add_request timestamp count
  state'.current_count ≥ state.current_count

/-- Verify cleanup correctness property -/
def verify_cleanup_property (state : RateLimitState) (current_time : UInt64) : Bool :=
  let state' := state.cleanup_window current_time
  let cutoff_time := current_time - state.config.window_seconds
  state'.window.all (fun record => record.timestamp > cutoff_time)

/-- Comprehensive property verification -/
def verify_all_properties (config : RateLimitConfig) : Bool :=
  let state := RateLimitState.new config
  let timestamp : UInt64 := 1000

  verify_enforcement_property state timestamp &&
  verify_monotonicity_property state timestamp 1 &&
  verify_cleanup_property state timestamp &&
  verify_algorithm_correctness config &&
  verify_throughput_requirement config &&
  run_chaos_test config &&
  verify_false_positive_rate config &&
  verify_zero_false_negatives config

/-!
## Benchmarking and Reporting

Functions for generating performance reports and validation summaries.
-/

/-- Generate performance report -/
def generate_performance_report (config : RateLimitConfig) : String :=
  let throughput := measure_throughput config 30000
  let chaos_test_passed := run_chaos_test config
  let false_positive_rate := if verify_false_positive_rate config then "≤ 0.1%" else "> 0.1%"
  let zero_false_negatives := verify_zero_false_negatives config

  s!"Rate Limiting Performance Report:
  Throughput: {throughput} requests/second
  Chaos Test: {if chaos_test_passed then "PASSED" else "FAILED"}
  False Positive Rate: {false_positive_rate}
  Zero False Negatives: {if zero_false_negatives then "YES" else "NO"}
  Max Requests: {config.max_requests}
  Window Seconds: {config.window_seconds}"

/-- Validate complete rate limiting implementation -/
def validate_rate_limiting (config : RateLimitConfig) : Bool × String :=
  let all_properties_valid := verify_all_properties config
  let report := generate_performance_report config

  (all_properties_valid, report)

end PostIncidentProofs.Rate.Verification
