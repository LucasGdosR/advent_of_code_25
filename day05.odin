#+private file
package aoc

import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sync"

global_intervals: [][2]int
global_results: [2]int

@private
solve_day_05 :: proc() -> Results
{
    this_idx := context.user_index
    // Parse merged intervals into a single slice.
    if this_idx == 0
    {
        // Parse
        it := string(INPUT)
        INTERVALS_IN_INPUT :: 177
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
                global_results[1] += interval[1] - interval[0]
                interval = i
            }
            else do interval[1] = max(interval[1], i[1])
        }
        intervals[count] = interval
        count += 1
        global_results[1] += count + interval[1] - interval[0]

        // Slice
        global_intervals = intervals[:count]
    }

    sync.barrier_wait(&BARRIER)

    local_part_1: int
    s, e := split_lines_roughly(INPUT)
    it := string(INPUT[s:e])
    for line in strings.split_lines_iterator(&it)
    {
        id, _ := strconv.parse_int(line)
        local_part_1 += binary_search(global_intervals, id)
    }

    sync.atomic_add_explicit(&global_results[0], local_part_1, sync.Atomic_Memory_Order.Relaxed)
    sync.barrier_wait(&BARRIER)

    return this_idx == 0 ? make_results(global_results) : Results{}
}

binary_search :: #force_inline proc(intervals: [][2]int, id: int) -> int
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
