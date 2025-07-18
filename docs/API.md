# Post-Incident-Proofs API Documentation

## Overview

The Post-Incident-Proofs system provides a comprehensive API for creating tamper-evident logging chains, enforcing rate limits with formal proofs, managing versioned rollbacks, and generating forensic evidence bundles.

## Quick Start

```lean
import PostIncidentProofs

-- Initialize the system
def main : IO Unit := do
  -- Create a tamper-evident log entry
  let entry := createLogEntry "User login attempt"
  appendLogEntry entry

  -- Check rate limiting
  let request := { ip := "192.168.1.100", timestamp := getMonotonicTime }
  let allowed := checkRateLimit request

  -- Generate incident bundle
  let bundle := buildIncidentBundle logs specs
  IO.println s!"Bundle generated: {bundle.size} bytes"
```

## Core Components

### 1. Tamper-Evident Logging

#### Creating Log Entries

```lean
-- Create a basic log entry
let entry := createLogEntry "Application started"

-- Create a detailed log entry with custom level
let detailed_entry := {
  timestamp := getMonotonicTime
  level := LogLevel.Warning
  message := "High memory usage detected"
  counter := getNextCounter
  hmac := ByteArray.empty  -- Will be computed automatically
}

-- Append entry to the chain
appendLogEntry entry
```

#### Verifying Log Chain Integrity

```lean
-- Verify the entire log chain
let is_valid := verifyLogChain log_chain

-- Verify a specific range of entries
let range_valid := verifyLogChainRange log_chain 100 200

-- Get verification statistics
let stats := getVerificationStats log_chain
IO.println s!"Chain length: {stats.chain_length}"
IO.println s!"Verification time: {stats.verification_time}"
```

### 2. Rate Limiting with Formal Proofs

#### Basic Rate Limiting

```lean
-- Define rate limit window
let window := {
  rateLimit := 1000  -- 1000 requests
  windowSize := Duration.seconds 60  -- per minute
}

-- Check if request is allowed
let request := { ip := "192.168.1.100", timestamp := getMonotonicTime }
let allowed := checkRateLimit request window

if allowed then
  IO.println "Request allowed"
else
  IO.println "Request rate limited"
```

#### Advanced Rate Limiting

```lean
-- Apply rate limiting to a batch of requests
let requests := generateTestRequests 10000
let filtered := applyRateLimit requests window

-- Get rate limiting statistics
let stats := getRateLimitStats window
IO.println s!"Total requests: {stats.total_requests}"
IO.println s!"Allowed requests: {stats.allowed_requests}"
IO.println s!"Rejected requests: {stats.rejected_requests}"
IO.println s!"False positive rate: {stats.false_positive_rate}"
```

### 3. Version Control with Invertible Operations

#### Creating Diffs

```lean
-- Create a diff between two states
let old_state := loadState "config_v1.json"
let new_state := loadState "config_v2.json"
let diff := createDiff old_state new_state

-- Apply the diff
let updated_state := applyDiff diff old_state

-- Verify the diff is invertible
let reverted_state := applyDiff (revertDiff diff) updated_state
let is_invertible := old_state == reverted_state
```

#### Batch Operations

```lean
-- Apply multiple diffs in sequence
let diffs := [diff1, diff2, diff3]
let final_state := diffs.foldl (fun state diff => applyDiff diff state) initial_state

-- Verify the entire sequence is invertible
let reverted_state := diffs.reverse.foldl (fun state diff => applyDiff (revertDiff diff) state) final_state
let sequence_invertible := initial_state == reverted_state
```

### 4. Dashboard Generation

#### Generating Grafana Dashboards

```lean
-- Generate dashboard from Lean specifications
let specs := loadSpecifications "src/PostIncidentProofs/"
let dashboard := generateGrafanaDashboard specs

-- Export to JSON
let dashboard_json := exportDashboardJSON dashboard
IO.FS.writeFile "dashboards/post-incident-proofs.json" dashboard_json
```

#### Generating Alert Rules

```lean
-- Generate Prometheus alert rules
let alert_rules := generateAlertingRules

-- Export to YAML
let rules_yaml := exportAlertRulesYAML alert_rules
IO.FS.writeFile "alerts/post-incident-proofs.yml" rules_yaml
```

### 5. Incident Bundle Generation

#### Creating Forensic Bundles

```lean
-- Build incident bundle with logs and specifications
let logs := getLogChain
let specs := loadSpecifications "src/"
let bundle := buildIncidentBundle logs specs

-- Generate HTML timeline
let timeline := generateHTMLTimeline logs
let bundle_with_timeline := addTimelineToBundle bundle timeline

-- Export bundle
let bundle_path := s!"incident-{getCurrentTimestamp}.zip"
exportBundle bundle_with_timeline bundle_path
```

#### Verifying Bundles

```lean
-- Verify bundle integrity
let bundle := loadBundle "incident-20231201-143022.zip"
let verification_result := verifyBundle bundle

case verification_result of
  | VerificationResult.Valid hash => IO.println s!"Bundle valid: {hash}"
  | VerificationResult.Invalid reason => IO.println s!"Bundle invalid: {reason}"
  | VerificationResult.Corrupted => IO.println "Bundle corrupted"
```

## Integration Examples

### Web Application Integration

```lean
-- HTTP server with post-incident-proofs integration
def handleRequest (request : HTTPRequest) : IO HTTPResponse := do
  -- Log the request
  let log_entry := createLogEntry s!"HTTP {request.method} {request.path}"
  appendLogEntry log_entry

  -- Apply rate limiting
  let rate_limit_request := { ip := request.client_ip, timestamp := getMonotonicTime }
  let allowed := checkRateLimit rate_limit_request

  if !allowed then
    pure { status := 429, body := "Rate limited" }
  else
    -- Process request
    let response := processRequest request

    -- Log the response
    let response_entry := createLogEntry s!"Response {response.status}"
    appendLogEntry response_entry

    pure response
```

### Database Integration

```lean
-- Database operations with version control
def updateUser (user_id : String) (updates : UserUpdates) : IO Unit := do
  -- Load current state
  let current_user := loadUser user_id

  -- Create diff
  let diff := createUserDiff current_user updates

  -- Apply diff
  let updated_user := applyDiff diff current_user

  -- Save with version control
  saveUserWithVersion user_id updated_user diff

  -- Log the operation
  let log_entry := createLogEntry s!"User {user_id} updated"
  appendLogEntry log_entry
```

### Microservice Integration

```lean
-- Microservice with comprehensive logging
def processOrder (order : Order) : IO OrderResult := do
  -- Start trace span
  let span ← createTraceSpan "process_order"
  let span := addTraceTag span "order_id" order.id

  -- Log order received
  let log_entry := createLogEntry s!"Order received: {order.id}"
  appendLogEntry log_entry

  -- Apply rate limiting
  let rate_request := { ip := order.client_ip, timestamp := getMonotonicTime }
  let allowed := checkRateLimit rate_request

  if !allowed then
    let span := addTraceLog span "Order rate limited"
    let span := finishTraceSpan span
    pure { success := false, error := "Rate limited" }
  else
    -- Process order
    let result := processOrderLogic order

    -- Log result
    let result_entry := createLogEntry s!"Order {order.id} processed: {result.success}"
    appendLogEntry result_entry

    let span := addTraceLog span s!"Order processed: {result.success}"
    let span := finishTraceSpan span

    pure result
```

## Performance Considerations

### High-Throughput Logging

```lean
-- Batch logging for high throughput
def batchLogEntries (entries : List String) : IO Unit := do
  let log_entries := entries.map createLogEntry
  batchAppendLogEntries log_entries
```

### Memory-Efficient Rate Limiting

```lean
-- Use sliding window with memory-efficient storage
let window := {
  rateLimit := 10000
  windowSize := Duration.seconds 60
  storage := SlidingWindowStorage.MemoryEfficient
}
```

### Optimized Bundle Generation

```lean
-- Generate bundle with compression
let bundle_config := {
  compression := BundleCompression.Gzip
  max_size := 5 * 1024 * 1024  -- 5MB
  include_timeline := true
  include_specs := true
}

let bundle := buildIncidentBundleWithConfig logs specs bundle_config
```

## Error Handling

### Graceful Degradation

```lean
-- Handle logging failures gracefully
def safeLogEntry (message : String) : IO Unit := do
  try
    let entry := createLogEntry message
    appendLogEntry entry
  catch e =>
    -- Fallback to basic logging
    IO.println s!"[FALLBACK] {message}"
    IO.println s!"Error: {e}"
```

### Rate Limiting Fallbacks

```lean
-- Fallback rate limiting when primary fails
def robustRateLimit (request : Request) : IO Bool := do
  try
    checkRateLimit request
  catch e =>
    -- Fallback to simple counter
    IO.println "Rate limiting failed, using fallback"
    simpleRateLimit request
```

## Security Best Practices

### Key Management

```lean
-- Rotate HMAC keys periodically
def rotateLoggingKey : IO Unit := do
  let new_key := generateSecureKey
  updateLoggingKey new_key

  -- Log key rotation
  let entry := createLogEntry "Logging key rotated"
  appendLogEntry entry
```

### Access Control

```lean
-- Verify bundle access permissions
def verifyBundleAccess (bundle : Bundle) (user : User) : IO Bool := do
  let has_permission := checkUserPermission user "bundle:read"
  let bundle_owner := getBundleOwner bundle

  pure (has_permission && (user.id == bundle_owner || user.role == "admin"))
```

## Monitoring and Observability

### Metrics Collection

```lean
-- Collect system metrics
def collectMetrics : IO Unit := do
  let metrics := collectSystemMetrics
  let prometheus_export := exportPrometheusMetrics metrics
  IO.FS.writeFile "/metrics" prometheus_export
```

### Health Checks

```lean
-- Run health checks
def runHealthChecks : IO (List HealthCheck) := do
  let checks := runHealthChecks
  let health_response := generateHealthResponse checks
  IO.FS.writeFile "/health" health_response
  pure checks
```

## Troubleshooting

### Common Issues

1. **Log Chain Verification Fails**

   - Check for clock skew between nodes
   - Verify HMAC key consistency
   - Review recent system changes

2. **Rate Limiting False Positives**

   - Adjust window size and rate limits
   - Check for network latency issues
   - Review concurrent request patterns

3. **Bundle Generation Slow**
   - Enable compression
   - Reduce included data
   - Use incremental bundle updates

### Debug Mode

```lean
-- Enable debug logging
def enableDebugMode : IO Unit := do
  setLogLevel LogLevel.Debug
  enableTraceLogging
  enablePerformanceProfiling
```

## API Reference

### Core Types

```lean
-- Log entry structure
structure LogEntry where
  timestamp : Time
  level : LogLevel
  message : String
  counter : Nat
  hmac : ByteArray

-- Rate limit window
structure RateLimitWindow where
  rateLimit : Nat
  windowSize : Duration

-- Request structure
structure Request where
  ip : String
  timestamp : Time
  method : String
  path : String

-- Diff structure
inductive Diff
  | Add : ByteArray → Diff
  | Delete : Nat → Diff
  | Modify : Nat → ByteArray → Diff

-- Bundle structure
structure Bundle where
  logs : List LogEntry
  specs : List String
  timeline : String
  hash : String
  size : Nat
```

### Core Functions

```lean
-- Logging functions
def createLogEntry (message : String) : LogEntry
def appendLogEntry (entry : LogEntry) : IO Unit
def verifyLogChain (entries : List LogEntry) : Bool
def getLogChain : List LogEntry

-- Rate limiting functions
def checkRateLimit (request : Request) (window : RateLimitWindow) : Bool
def applyRateLimit (requests : List Request) (window : RateLimitWindow) : List Request
def getRateLimitStats (window : RateLimitWindow) : RateLimitStats

-- Version control functions
def createDiff (old_state : ByteArray) (new_state : ByteArray) : Diff
def applyDiff (diff : Diff) (state : ByteArray) : ByteArray
def revertDiff (diff : Diff) : Diff

-- Bundle functions
def buildIncidentBundle (logs : List LogEntry) (specs : List String) : Bundle
def verifyBundle (bundle : Bundle) : VerificationResult
def generateHTMLTimeline (logs : List LogEntry) : String

-- Dashboard functions
def generateGrafanaDashboard (specs : List String) : Dashboard
def generateAlertingRules : String
def exportDashboardJSON (dashboard : Dashboard) : String
```

For more detailed information about specific components, see the individual module documentation in the source code.
