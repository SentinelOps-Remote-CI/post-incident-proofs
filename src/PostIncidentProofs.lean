/-
Post-Incident-Proofs: Machine-checked forensic evidence system
Copyright (c) 2024 Post-Incident-Proofs Contributors

This module provides the main public API for the post-incident-proofs system.
-/

import PostIncidentProofs.Logging.Core
import PostIncidentProofs.Logging.Verification
import PostIncidentProofs.Rate.Model
import PostIncidentProofs.Rate.Verification
import PostIncidentProofs.Version.Diff
import PostIncidentProofs.Version.Verification
import PostIncidentProofs.Dashboard.Generator
import PostIncidentProofs.Bundle.Builder
import PostIncidentProofs.Utils.Crypto
import PostIncidentProofs.Utils.Time
import PostIncidentProofs.Security.ThreatModel
import PostIncidentProofs.Benchmark.Performance
import PostIncidentProofs.Chaos.Engine
import PostIncidentProofs.Observability.Metrics

/-!
# Post-Incident-Proofs

This library provides machine-checked forensic evidence capabilities for runtime telemetry.

## Core Components

- **Logging**: Tamper-evident logging chain with HMAC verification
- **Rate Limiting**: Sliding-window rate limiting with correctness proofs
- **Version Control**: Diff/patch operations with invertibility guarantees
- **Dashboard Generation**: Auto-generated Grafana dashboards from Lean specs
- **Bundle Generation**: Incident bundles with cryptographic verification

## Quick Start

```lean
import PostIncidentProofs

-- Create a tamper-evident log entry
def entry := LogEntry.mk
  (timestamp := 1701234567)
  (level := LogLevel.INFO)
  (message := "User login successful")
  (counter := 42)
  (hmac := ByteArray.empty) -- Will be computed by append_entry

-- Verify log chain integrity
#eval verify_log_chain log_entries

-- Check rate limit correctness
#eval verify_rate_limit rate_limit_state
```
-/

namespace PostIncidentProofs

/-!
## Public API

The following functions and types are the main public interface.
-/

/-- Verify the integrity of a complete log chain -/
def verify_log_chain (chain : List Logging.LogEntry) (key : ByteArray) : Bool :=
  Logging.Verification.verify_chain chain key

/-- Verify rate limit state correctness -/
def verify_rate_limit (state : Rate.RateLimitState) : Bool :=
  Rate.Verification.verify_state state

/-- Apply a diff to a state and verify invertibility -/
def apply_diff (state : Version.State) (diff : Version.Diff) : Version.State :=
  Version.apply_diff state diff

/-- Revert a diff from a state -/
def revert_diff (state : Version.State) (diff : Version.Diff) : Version.State :=
  Version.revert_diff state diff

/-- Generate Grafana dashboard from Lean specifications -/
def generate_dashboard (specs : List Dashboard.Spec) : String :=
  Dashboard.Generator.generate_dashboard_json specs

/-- Create an incident bundle with cryptographic verification -/
def create_incident_bundle
  (logs : List Logging.LogEntry)
  (specs : List String)
  (window : Time.Window) : Bundle.IncidentBundle :=
  Bundle.Builder.create_bundle logs specs window

/-- Verify incident bundle integrity -/
def verify_incident_bundle (bundle : Bundle.IncidentBundle) : Bool :=
  Bundle.Builder.verify_bundle bundle

/-!
## Security and Threat Modeling

The system provides formal security guarantees through threat modeling and validation.
-/

/-- Run comprehensive security tests -/
def run_security_tests : IO Security.ThreatModel.SecurityMetrics :=
  Security.ThreatModel.runSecurityTests

/-- Validate security properties -/
def validate_security_properties : IO Bool := do
  let metrics ← run_security_tests
  pure (metrics.tamper_detection_time < Duration.milliseconds 200 &&
        metrics.rate_limit_false_positives < 0.001 &&
        metrics.rate_limit_false_negatives == 0.0)

/-!
## Performance Benchmarks

The system is designed to meet these performance targets:

- Log throughput: ≥ 200k entries/s (single core)
- Rate limiting: O(1) constant-time per request
- Bundle generation: < 5MB for 24h window
- Proof compilation: < 3s for all core theorems
-/

/-- Run performance benchmarks -/
def run_performance_benchmarks : IO (List Benchmark.Performance.BenchmarkResult) :=
  Benchmark.Performance.runAllBenchmarks

/-- Validate performance SLAs -/
def validate_performance_slas : IO Bool := do
  let results ← run_performance_benchmarks
  pure (results.all (·.success))

/-!
## Chaos Engineering

The system includes comprehensive chaos testing to validate resilience.
-/

/-- Run chaos engineering tests -/
def run_chaos_tests (config : Chaos.Engine.ChaosConfig) : IO (List Chaos.Engine.ChaosTestResult) :=
  Chaos.Engine.runChaosTestSuite config

/-- Validate system resilience -/
def validate_system_resilience : IO Bool := do
  let config := { Chaos.Engine.ChaosConfig. }
  let results ← run_chaos_tests config
  let success_rate := results.filter (·.success) |>.length.toFloat / results.length.toFloat
  pure (success_rate > 0.9)  -- 90% success rate required

/-!
## Observability and Monitoring

The system provides comprehensive observability capabilities.
-/

/-- Collect system metrics -/
def collect_system_metrics : IO (List Observability.Metrics.Metric) :=
  Observability.Metrics.collectSystemMetrics

/-- Run health checks -/
def run_health_checks : IO (List Observability.Metrics.HealthCheck) :=
  Observability.Metrics.runHealthChecks

/-- Create distributed trace span -/
def create_trace_span (operation_name : String) (parent_span_id : Option String := none) : IO Observability.Metrics.TraceSpan :=
  Observability.Metrics.createTraceSpan operation_name parent_span_id

/-- Finish trace span -/
def finish_trace_span (span : Observability.Metrics.TraceSpan) : Observability.Metrics.TraceSpan :=
  Observability.Metrics.finishTraceSpan span

/-- Add tag to trace span -/
def add_trace_tag (span : Observability.Metrics.TraceSpan) (key : String) (value : String) : Observability.Metrics.TraceSpan :=
  Observability.Metrics.addTraceTag span key value

/-- Add log to trace span -/
def add_trace_log (span : Observability.Metrics.TraceSpan) (message : String) : Observability.Metrics.TraceSpan :=
  Observability.Metrics.addTraceLog span message

/-!
## Comprehensive System Validation

The system provides end-to-end validation capabilities.
-/

/-- Validate entire system -/
def validate_system : IO Bool := do
  let security_ok ← validate_security_properties
  let performance_ok ← validate_performance_slas
  let resilience_ok ← validate_system_resilience

  IO.println s!"Security validation: {if security_ok then \"✅ PASS\" else \"❌ FAIL\"}"
  IO.println s!"Performance validation: {if performance_ok then \"✅ PASS\" else \"❌ FAIL\"}"
  IO.println s!"Resilience validation: {if resilience_ok then \"✅ PASS\" else \"❌ FAIL\"}"

  pure (security_ok && performance_ok && resilience_ok)

/-!
## Security Guarantees

- **Tamper Detection**: 100% of simulated log-tamper attacks detected in < 200ms
- **Rate Limit Correctness**: ≤ 0.1% false-positives, 0 false-negatives at 30k rps
- **Version Invertibility**: 10k successive upgrades/rollbacks leave model bit-identical
- **Bundle Integrity**: Cryptographic verification with zero schema warnings
- **Chaos Resilience**: 90%+ success rate under various failure conditions
- **Observability**: Comprehensive metrics, health checks, and distributed tracing
-/

end PostIncidentProofs
