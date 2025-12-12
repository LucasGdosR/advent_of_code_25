#+private file
package aoc

import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sync"

INTERVALS_IN_INPUT :: 177

global_intervals: [][2]int
global_results: [2]int

@private
solve_day_05_st :: proc() -> [2]int
{
    if context.user_index == 0
    {
        intervals, result_part_2 := make_merged_intervals()
        return [2]int{ check_ids(intervals, 0, len(INPUT)), result_part_2 }
    }
    else do return [2]int{}
}

@private
solve_day_05_mt :: proc() -> [2]int
{
    this_idx := context.user_index
    if this_idx == 0 do global_intervals, global_results[1] = make_merged_intervals()

    sync.barrier_wait(&BARRIER)

    s, e := split_lines_roughly(INPUT)

    sync.atomic_add_explicit(&global_results[0], check_ids(global_intervals, s, e), sync.Atomic_Memory_Order.Relaxed)
    sync.barrier_wait(&BARRIER)

    return this_idx == 0 ? global_results : [2]int{}
}

make_merged_intervals :: proc() -> ([][2]int, int)
{
    result_part_2: int
    // Parse merged intervals into a single slice.
    // Parse
    it := string(INPUT)
    intervals := make([dynamic][2]int, 0, INTERVALS_IN_INPUT)
    for
    {
        line, _ := strings.split_lines_iterator(&it)
        if len(line) == 0 do break
        start, _ := strings.split_iterator(&line, "-")
        end := line
        s, _ := strconv.parse_int(start, 10)
        e, _ := strconv.parse_int(end, 10)
        append(&intervals, [2]int{s, e})
    }
    INPUT = transmute([]u8)it

    // Sort
    slice.sort_by_key(intervals[:], proc(e: [2]int) -> int { return e[0] })

    // Merge
    count := 0
    interval := intervals[0]
    for i in intervals
    {
        if i[0] > interval[1]
        {
            intervals[count] = interval
            count += 1
            result_part_2 += interval[1] - interval[0]
            interval = i
        }
        else do interval[1] = max(interval[1], i[1])
    }
    intervals[count] = interval
    count += 1
    result_part_2 += count + interval[1] - interval[0]

    // Slice
    return intervals[:count], result_part_2
}

check_ids :: proc(intervals: [][2]int, start, end: int) -> int
{
    result_part_1: int
    it := string(INPUT[start:end])
    for line in strings.split_lines_iterator(&it)
    {
        id, _ := strconv.parse_int(line)
        result_part_1 += binary_search(intervals, id)
    }
    return result_part_1
}

binary_search :: proc "contextless" (intervals: [][2]int, id: int) -> int
{
    left, right := 0, len(intervals)
    for left < right
    {
        mid := (left + right) / 2
        interval := intervals[mid]
        if id < interval[0] do right = mid
        else if id > interval[1] do left = mid + 1
        else do return 1
    }
    return 0
}
