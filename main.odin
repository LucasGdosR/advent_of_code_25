package aoc

import "core:fmt"
import "core:math"
import "core:os"
import "core:sync"
import "core:thread"
import vmem "core:mem/virtual"

NUMBER_OF_CORES: int
BARRIER: sync.Barrier

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

  for solve_day, day in solutions {
    day_results := solve_day()
    if i == 0 do os.write_string(results, fmt.aprintfln(
      "Day %v:\nPart 1: %v\nPart 2: %v\n\n",
      day+1, day_results.p1, day_results.p2))
    free_all(allocator)
  }

  if i == 0 do os.close(results)
  vmem.arena_destroy(&thread_arena)
}

// Inclusive [start, end) non-inclusive
split_count_evenly :: proc(count: int) -> (start: int, end: int)
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
split_lines_roughly :: proc(data: []byte) -> (start: int, end: int)
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

make_results_int :: proc(results: [2]int) -> Results
{
    return Results {p1=fmt.aprint(results[0]), p2=fmt.aprint(results[1])}
}

make_results :: proc{make_results_int}

solutions := [?] proc() -> Results {
  solve_day_01,
  solve_day_02,
  solve_day_03,
}
