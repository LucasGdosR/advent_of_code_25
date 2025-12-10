package aoc

import "core:fmt"
import "core:math"
import "core:os"
import "core:sync"
import "core:thread"
import "core:time"
import vmem "core:mem/virtual"

NUMBER_OF_CORES: int
BARRIER: sync.Barrier
INPUT: []u8

Results :: struct {
  p1, p2: string
}

main :: proc()
{
  NUMBER_OF_CORES = os.processor_core_count()
  threads := make([]^thread.Thread, NUMBER_OF_CORES, context.temp_allocator)
  sync.barrier_init(&BARRIER, NUMBER_OF_CORES)
  for i in 0..<NUMBER_OF_CORES do threads[i] = thread.create_and_start_with_data(rawptr(uintptr(i)), entry_point)
  thread.join_multiple(..threads)
  free_all(context.temp_allocator)
}

@(private="file")
entry_point :: proc(data: rawptr)
{
  i := int(uintptr(data))
  context.user_index = i

  results: os.Handle
  if i == 0
  {
    ok: os.Error
    results, ok = os.open("results", os.O_CREATE | os.O_TRUNC | os.O_WRONLY, os.S_IRUSR | os.S_IWUSR)
    assert(ok == os.General_Error.None, "failed opening results file")
  }

  thread_arena: vmem.Arena
  allocator := vmem.arena_allocator(&thread_arena)
  context.allocator = allocator

  for solve_day, s_idx in solutions {
    if s_idx == 1 || s_idx == 13 do continue // Days 1 and 7 have no multithreaded implementation.
    // Reading the input is not part of the benchmark.
    day := (s_idx / 2) + 1
    if i == 0
    {
      ok: bool
      INPUT, ok = os.read_entire_file(fmt.aprintf(
        "input/%v%v",
        day/10, day%10))
      if !ok
      {
        fmt.println("File for day", day, "does not exist.")
        os.exit(1)
      }
    }
    sync.barrier_wait(&BARRIER) // Assert all threads can read the input.

    start := time.tick_now()
    day_results := solve_day()
    us := time.duration_microseconds(time.tick_diff(start, time.tick_now()))

    if i == 0 do os.write_string(results, fmt.aprintf(
      "Day %v %v:\nPart 1: %v\nPart 2: %v\n\nMicroseconds: %.f\n\n",
      day, s_idx & 1 == 0 ? "single-threaded" : "multi-threaded", day_results.p1, day_results.p2, us))
    free_all(allocator)
  }

  if i == 0 do os.close(results)
  vmem.arena_destroy(&thread_arena)
}

// Inclusive [start, end) non-inclusive
split_count_evenly :: #force_inline proc(count: int) -> (start, end: int)
{
  this_idx := context.user_index

  per_thread, total_leftover := math.divmod(count, NUMBER_OF_CORES)

  this_has_leftover := this_idx < total_leftover
  leftovers_before_this := this_has_leftover ? this_idx : total_leftover

  start = per_thread * this_idx + leftovers_before_this
  end = start + per_thread + int(this_has_leftover)
  return
}

// Used for non-standard line lengths.
split_lines_roughly :: #force_inline proc(data: []byte) -> (start, end: int)
{
  start, end = split_count_evenly(len(data))
  if start != 0
  {
    for data[start] != '\n' do start += 1
    start += 1
  }
  if end != len(data) do for data[end] != '\n' do end += 1
  return
}

global_starts_ends: []int
// Used for ranges with linear work (first index has twice the average work, last has 0).
// Should be used by a single thread.
split_linear_work :: #force_inline proc(k: int)
{
  global_starts_ends = make([]int, NUMBER_OF_CORES+1)
  total_work := k * (k - 1) / 2
	step := (total_work + NUMBER_OF_CORES - 1) / NUMBER_OF_CORES
	for start, i := 0, 0; i < NUMBER_OF_CORES; i += 1
  {
    // This distributes work evenly between threads. Trust me.
		end := i == NUMBER_OF_CORES-1 ? k : k - int(math.sqrt(f64(k*k-2*k*(start+1)+start*start+2*start-2*step+1)))
		global_starts_ends[i+1] = end
		start = end
	}
}

make_results_int :: #force_inline proc(results: [2]int) -> Results
{
    return Results {p1=fmt.aprint(results[0]), p2=fmt.aprint(results[1])}
}

make_results :: proc{make_results_int}

@(private="file")
solutions := [?] proc() -> Results {
  solve_day_01_st,
  solve_day_01_mt,
  solve_day_02_st,
  solve_day_02_mt,
  solve_day_03_st,
  solve_day_03_mt,
  solve_day_04_st,
  solve_day_04_mt,
  solve_day_05_st,
  solve_day_05_mt,
  solve_day_06_st,
  solve_day_06_mt,
  solve_day_07_st,
  solve_day_07_mt,
  solve_day_08_st,
  solve_day_08_mt,
  solve_day_09_st,
  solve_day_09_mt,
}
