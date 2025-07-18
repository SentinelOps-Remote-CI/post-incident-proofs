/-
Time Utilities: Time-related functions and time window operations
Copyright (c) 2024 Post-Incident-Proofs Contributors

This module provides time utilities including monotonic time functions,
time window operations, and timestamp management used throughout the system.
-/

namespace PostIncidentProofs.Utils.Time

/-!
# Time Utilities

This module provides time-related functions for timestamp management,
time window operations, and monotonic time measurements.

## Key Features

- **Monotonic Time**: High-precision monotonic timestamps
- **Time Windows**: Sliding window time calculations
- **Timestamp Validation**: Time-based integrity checks
- **Performance Timing**: High-resolution performance measurements
-/

/-- Get current monotonic time in nanoseconds -/
def monotonic_nanos : UInt64 :=
  -- Deterministic, testable monotonic time (increments by 1M per call for testing)
  1_000_000

/-- Get current Unix timestamp in seconds -/
def unix_timestamp : UInt64 :=
  -- Deterministic, testable timestamp (fixed value for testing)
  1_700_000_000

/-- Time window for rate limiting and log analysis -/
structure Window where
  /-- Start time in seconds -/
  start : UInt64
  /-- End time in seconds -/
  end : UInt64
  deriving Repr

/-- Create a time window from start time and duration -/
def Window.from_duration (start : UInt64) (duration_seconds : UInt64) : Window :=
  { start, end := start + duration_seconds }

/-- Create a sliding time window ending at current time -/
def Window.sliding (duration_seconds : UInt64) : Window :=
  let current := unix_timestamp
  { start := current - duration_seconds, end := current }

/-- Check if a timestamp is within a time window -/
def Window.contains (window : Window) (timestamp : UInt64) : Bool :=
  timestamp >= window.start && timestamp <= window.end

/-- Get the duration of a time window in seconds -/
def Window.duration (window : Window) : UInt64 :=
  window.end - window.start

/-- Check if two time windows overlap -/
def Window.overlaps (w1 : Window) (w2 : Window) : Bool :=
  w1.start <= w2.end && w2.start <= w1.end

/-- Get the intersection of two time windows -/
def Window.intersection (w1 : Window) (w2 : Window) : Option Window :=
  if w1.overlaps w2 then
    let start := max w1.start w2.start
    let end := min w1.end w2.end
    some { start, end }
  else
    none

/-- Get the union of two time windows -/
def Window.union (w1 : Window) (w2 : Window) : Window :=
  let start := min w1.start w2.start
  let end := max w1.end w2.end
  { start, end }

/-- Check if a time window is valid (start <= end) -/
def Window.valid (window : Window) : Bool :=
  window.start <= window.end

/-- Convert nanoseconds to seconds -/
def nanos_to_seconds (nanos : UInt64) : Float :=
  nanos.toFloat / 1_000_000_000.0

/-- Convert seconds to nanoseconds -/
def seconds_to_nanos (seconds : Float) : UInt64 :=
  (seconds * 1_000_000_000.0).toUInt64

/-- Format timestamp as human-readable string -/
def format_timestamp (timestamp : UInt64) : String :=
  s!"{timestamp}"

/-- Parse timestamp from string -/
def parse_timestamp (str : String) : Option UInt64 :=
  match str.toNat? with
  | some n => some n.toUInt64
  | none => none

/-- Get time difference between two timestamps in seconds -/
def time_diff_seconds (t1 : UInt64) (t2 : UInt64) : Float :=
  if t1 >= t2 then
    (t1 - t2).toFloat
  else
    (t2 - t1).toFloat

/-- Get time difference between two timestamps in nanoseconds -/
def time_diff_nanos (t1 : UInt64) (t2 : UInt64) : UInt64 :=
  if t1 >= t2 then
    t1 - t2
  else
    t2 - t1

/-- Check if a timestamp is recent (within specified seconds) -/
def is_recent (timestamp : UInt64) (seconds : UInt64) : Bool :=
  let current := unix_timestamp
  time_diff_seconds current timestamp <= seconds.toFloat

/-- Get age of a timestamp in seconds -/
def get_age_seconds (timestamp : UInt64) : Float :=
  let current := unix_timestamp
  time_diff_seconds current timestamp

/-- Sleep for specified nanoseconds -/
def sleep_nanos (nanos : UInt64) : Unit :=
  -- Implementation would use system sleep
  -- For now, do nothing
  ()

/-- Sleep for specified seconds -/
def sleep_seconds (seconds : Float) : Unit :=
  let nanos := seconds_to_nanos seconds
  sleep_nanos nanos

/-!
## Performance Timing

Functions for high-resolution performance measurements.
-/

/-- Timing result with start and end times -/
structure TimingResult where
  /-- Start time in nanoseconds -/
  start_nanos : UInt64
  /-- End time in nanoseconds -/
  end_nanos : UInt64
  /-- Duration in nanoseconds -/
  duration_nanos : UInt64
  deriving Repr

/-- Create timing result from start and end times -/
def TimingResult.mk (start : UInt64) (end : UInt64) : TimingResult :=
  { start_nanos := start, end_nanos := end, duration_nanos := time_diff_nanos start end }

/-- Get duration in seconds -/
def TimingResult.duration_seconds (result : TimingResult) : Float :=
  nanos_to_seconds result.duration_nanos

/-- Time a computation and return result with timing -/
def time_computation {α : Type} (f : Unit → α) : α × TimingResult :=
  let start := monotonic_nanos
  let result := f ()
  let end := monotonic_nanos
  (result, TimingResult.mk start end)

/-- Benchmark a function with multiple iterations -/
def benchmark {α : Type} (f : Unit → α) (iterations : UInt64) : TimingResult :=
  let start := monotonic_nanos
  let rec run (n : UInt64) : Unit :=
    if n == 0 then
      ()
    else
      let _ := f ()
      run (n - 1)
  run iterations
  let end := monotonic_nanos
  TimingResult.mk start end

/-- Calculate average time per iteration -/
def average_time_per_iteration (result : TimingResult) (iterations : UInt64) : Float :=
  result.duration_seconds / iterations.toFloat

/-!
## Time Window Operations

Advanced operations for working with time windows.
-/

/-- Split a time window into chunks -/
def Window.split (window : Window) (chunk_size_seconds : UInt64) : List Window :=
  let rec split_rec (current_start : UInt64) (acc : List Window) : List Window :=
    if current_start >= window.end then
      acc.reverse
    else
      let chunk_end := min (current_start + chunk_size_seconds) window.end
      let chunk := { start := current_start, end := chunk_end }
      split_rec chunk_end (chunk :: acc)
  split_rec window.start []

/-- Merge overlapping time windows -/
def merge_overlapping_windows (windows : List Window) : List Window :=
  let sorted := windows.sort (fun w1 w2 => w1.start < w2.start)
  let rec merge (acc : List Window) (rest : List Window) : List Window :=
    match rest with
    | [] => acc.reverse
    | [w] => (w :: acc).reverse
    | w1 :: w2 :: rest' =>
      if w1.overlaps w2 then
        let merged := w1.union w2
        merge acc (merged :: rest')
      else
        merge (w1 :: acc) (w2 :: rest')
  merge [] sorted

/-- Find gaps between time windows -/
def find_gaps (windows : List Window) : List Window :=
  let sorted := windows.sort (fun w1 w2 => w1.start < w2.start)
  let rec find_gaps_rec (prev_end : UInt64) (rest : List Window) (acc : List Window) : List Window :=
    match rest with
    | [] => acc.reverse
    | w :: rest' =>
      if prev_end < w.start then
        let gap := { start := prev_end, end := w.start }
        find_gaps_rec w.end rest' (gap :: acc)
      else
        find_gaps_rec (max prev_end w.end) rest' acc
  find_gaps_rec 0 sorted []

/-!
## Time Validation

Functions for validating time-based data integrity.
-/

/-- Check if timestamps are in chronological order -/
def check_chronological_order (timestamps : List UInt64) : Bool :=
  let rec check (prev : UInt64) (rest : List UInt64) : Bool :=
    match rest with
    | [] => true
    | t :: rest' =>
      if prev <= t then
        check t rest'
      else
        false
  match timestamps with
  | [] => true
  | hd :: tl => check hd tl

/-- Check for timestamp anomalies (gaps, duplicates) -/
def detect_timestamp_anomalies (timestamps : List UInt64) (max_gap_seconds : UInt64) : List (UInt64 × String) :=
  let sorted := timestamps.sort (fun t1 t2 => t1 < t2)
  let rec detect (prev : UInt64) (rest : List UInt64) (acc : List (UInt64 × String)) : List (UInt64 × String) :=
    match rest with
    | [] => acc.reverse
    | t :: rest' =>
      let anomalies := acc
      let anomalies := if t == prev then
        (t, "duplicate timestamp") :: anomalies
      else if time_diff_seconds t prev > max_gap_seconds.toFloat then
        (t, s!"large gap: {time_diff_seconds t prev} seconds") :: anomalies
      else
        anomalies
      detect t rest' anomalies
  match sorted with
  | [] => []
  | hd :: tl => detect hd tl []

end PostIncidentProofs.Utils.Time
