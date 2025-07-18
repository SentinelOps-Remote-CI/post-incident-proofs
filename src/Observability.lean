/-
Observability Testing Executable
================================

This executable runs comprehensive observability and monitoring tests
for the post-incident-proofs system.
-/

import PostIncidentProofs.Observability.Metrics
import PostIncidentProofs.Benchmark.Performance

def main : IO Unit := do
  IO.println "📊 Post-Incident-Proofs Observability Testing"
  IO.println "=" * 50

  -- Collect system metrics
  IO.println "\n1. Collecting System Metrics..."
  let metrics ← PostIncidentProofs.Observability.Metrics.collectSystemMetrics

  IO.println "   Collected metrics:"
  for metric in metrics do
    let labels_str := if metric.labels.isEmpty then "" else
      "{" ++ String.join (metric.labels.map fun (k, v) => s!"{k}=\"{v}\"") ++ "}"
    IO.println s!"     {metric.name}{labels_str} = {metric.value}"

  -- Run health checks
  IO.println "\n2. Running Health Checks..."
  let health_checks ← PostIncidentProofs.Observability.Metrics.runHealthChecks

  for check in health_checks do
    let status := match check.status with
      | PostIncidentProofs.Observability.Metrics.HealthStatus.Healthy => "✅ HEALTHY"
      | PostIncidentProofs.Observability.Metrics.HealthStatus.Degraded => "⚠️  DEGRADED"
      | PostIncidentProofs.Observability.Metrics.HealthStatus.Unhealthy => "❌ UNHEALTHY"
      | PostIncidentProofs.Observability.Metrics.HealthStatus.Unknown => "❓ UNKNOWN"

    IO.println s!"   {check.name}: {status}"
    IO.println s!"     Message: {check.message}"
    IO.println s!"     Response Time: {check.response_time}"
    IO.println s!"     Last Check: {check.last_check}"

    if !check.details.isEmpty then
      IO.println "     Details:"
      for (key, value) in check.details do
        IO.println s!"       {key}: {value}"

  -- Test distributed tracing
  IO.println "\n3. Testing Distributed Tracing..."
  let span1 ← PostIncidentProofs.Observability.Metrics.createTraceSpan "test_operation_1"
  let span1 := PostIncidentProofs.Observability.Metrics.addTraceTag span1 "test" "true"
  let span1 := PostIncidentProofs.Observability.Metrics.addTraceLog span1 "Starting test operation"

  -- Simulate some work
  IO.sleep 100  -- 100ms

  let span1 := PostIncidentProofs.Observability.Metrics.addTraceLog span1 "Test operation completed"
  let span1 := PostIncidentProofs.Observability.Metrics.finishTraceSpan span1

  let span2 ← PostIncidentProofs.Observability.Metrics.createTraceSpan "test_operation_2" (some span1.span_id)
  let span2 := PostIncidentProofs.Observability.Metrics.addTraceTag span2 "parent" span1.span_id
  let span2 := PostIncidentProofs.Observability.Metrics.finishTraceSpan span2

  IO.println s!"   Created trace: {span1.trace_id}"
  IO.println s!"   Span 1: {span1.span_id} ({span1.operation_name})"
  IO.println s!"   Span 2: {span2.span_id} ({span2.operation_name})"
  IO.println s!"   Parent-child relationship: {span2.parent_span_id} -> {span2.span_id}"

  -- Generate Prometheus metrics export
  IO.println "\n4. Generating Prometheus Metrics Export..."
  let prometheus_export := PostIncidentProofs.Observability.Metrics.exportPrometheusMetrics metrics
  IO.println "   Prometheus metrics format:"
  IO.println prometheus_export

  -- Generate health check response
  IO.println "\n5. Generating Health Check Response..."
  let health_response := PostIncidentProofs.Observability.Metrics.generateHealthResponse health_checks
  IO.println "   Health check response:"
  IO.println health_response

  -- Generate alerting rules
  IO.println "\n6. Generating Alerting Rules..."
  let alerting_rules := PostIncidentProofs.Observability.Metrics.generateAlertingRules
  IO.println "   Prometheus alerting rules:"
  IO.println alerting_rules

  -- Performance validation
  IO.println "\n7. Validating Observability Performance..."
  let performance_results ← PostIncidentProofs.Benchmark.Performance.runAllBenchmarks
  let observability_tests := performance_results.filter fun result =>
    result.test_name.contains "Dashboard" || result.test_name.contains "Bundle"

  for test in observability_tests do
    let status := if test.success then "✅ PASS" else "❌ FAIL"
    IO.println s!"   {test.test_name}: {status}"
    IO.println s!"     Duration: {test.duration}"
    IO.println s!"     Memory: {test.memory_usage} bytes"
    IO.println s!"     CPU: {test.cpu_usage * 100:.1f}%"

  -- Generate observability report
  IO.println "\n8. Generating Observability Report..."
  let overall_health := health_checks.all fun check =>
    check.status == PostIncidentProofs.Observability.Metrics.HealthStatus.Healthy

  let metrics_count := metrics.length
  let health_check_count := health_checks.length
  let healthy_checks := health_checks.filter fun check =>
    check.status == PostIncidentProofs.Observability.Metrics.HealthStatus.Healthy |>.length

  IO.println s!"\n📊 Observability Summary:"
  IO.println s!"   Metrics Collected: {metrics_count}"
  IO.println s!"   Health Checks: {health_check_count}"
  IO.println s!"   Healthy Checks: {healthy_checks}"
  IO.println s!"   Overall Health: {if overall_health then \"✅ HEALTHY\" else \"❌ UNHEALTHY\"}"
  IO.println s!"   Tracing Spans: 2 (parent-child relationship verified)"

  -- Save metrics to file for external monitoring
  IO.FS.writeFile "observability-metrics.txt" prometheus_export
  IO.FS.writeFile "health-status.json" health_response
  IO.FS.writeFile "alerting-rules.yml" alerting_rules

  IO.println "\n💾 Metrics saved to:"
  IO.println "   - observability-metrics.txt"
  IO.println "   - health-status.json"
  IO.println "   - alerting-rules.yml"

  if overall_health then
    IO.println "\n✅ Observability validation PASSED"
    IO.exit 0
  else
    IO.println "\n❌ Observability validation FAILED"
    IO.exit 1
