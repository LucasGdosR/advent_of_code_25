#+private file
package aoc

import "core:strconv"
import "core:strings"
import "core:sync"

INTERVALS :: 38

global_intervals: [][2]string
global_task_counter: int

@private
solve_day_02_st :: proc() -> [2]int
{
    if context.user_index == 0
    {
        results: [2]int
        intervals := make_intervals()
        buffer := make([]u8, 16)
        for interval in intervals do results += process_interval(interval, buffer)
        return results
    }
    else do return [2]int{}
}

@private
solve_day_02_mt :: proc() -> [2]int
{
    results: [2]int
    if context.user_index == 0
    {
        global_intervals = make_intervals()
        sync.atomic_store_explicit(&INPUT_PARSED, true, .Release)
    }
    buffer := make([]u8, 16)

    for !sync.atomic_load_explicit(&INPUT_PARSED, .Acquire) {}

    interval_count := len(global_intervals)

    for//ever
    {
        interval_idx := sync.atomic_add_explicit(&global_task_counter, 1, .Relaxed)
        if interval_idx >= interval_count do break
        interval := global_intervals[interval_idx]
        results += process_interval(interval, buffer)
    }
    return sum_local_results(results)
}

make_intervals :: proc() -> [][2]string
{
    dyn_arr := make([dynamic][2]string, 0, INTERVALS)
    it := string(INPUT)
    for range in strings.split_iterator(&it, ",")
    {
        range := range
        start, _ := strings.split_iterator(&range, "-")
        end := range
        append(&dyn_arr, [2]string{start, end})
    }
    return dyn_arr[:]
}

process_interval :: proc  (interval: [2]string, buffer:[]u8) -> [2]int
{
    results: [2]int
    start, end := interval[0], interval[1]

    length := len(start)
    same_length := length == len(end)
    start_is_odd := bool(length & 1)

    // Ranges with odd length cannot have two numbers repeating
    // There are no inputs where len(start) + 2 <= len(end), therefore this is valid
    if !same_length || !start_is_odd
    {
        // Treat each half of the interval as another interval.
        left_interval: [2]int
        right_start, _ := strconv.parse_int(start[length  / 2 :])
        right_end, _ := strconv.parse_int(end[(length + int(start_is_odd)) / 2 :])
        if same_length do left_interval = { strconv.parse_int(start[:length/2]) or_else 0, strconv.parse_int(end[:length/2]) or_else 0 }
        // Start is odd, so increase it to the next power of 10
        else if start_is_odd
        {
            left_interval = { next_power_of_10(strconv.parse_int(start[:length/2]) or_else 0), strconv.parse_int(end[:(length+1)/2]) or_else 0 }
            right_start = 0
        }
        else // End is odd, so shift it to (the next power of 10 after start) - 1
        {
            lstart, _ := strconv.parse_int(start[:length/2])
            left_interval = { lstart, next_power_of_10(lstart) - 1 }
            right_end = left_interval[1]
        }

        // There's a single number to try
        if left_interval[0] == left_interval[1]
        {
            n := left_interval[0]
            if right_start <= n && right_end >= n do results[0] += n + n * next_power_of_10(n)
        }
        else
        {
            p10 := next_power_of_10(left_interval[0])
            if right_start <= left_interval[0] do results[0] += left_interval[0] + left_interval[0] * p10
            if right_end >= left_interval[1] do results[0] += left_interval[1] + left_interval[1] * p10
            for i in left_interval[0]+1..=left_interval[1]-1 do results[0] += i + i * p10
        }
    }

    // Part 2:
    max_pattern_length := len(end) / 2
    s, _ := strconv.parse_int(start)
    e, _ := strconv.parse_int(end)
    // For every number in the range s-e
    for n in s..=e
    {
        n_str := strconv.write_int(buffer, i64(n), 10)
        n_len := len(n_str)
        // Try different pattern lengths
        if n_len > 1 do for plen in 1..=max_pattern_length do if n_len % plen == 0
        {
            // Check if this number follows this pattern
            pattern_matched := true
            for i in 0..<(n_len/plen - 1) do if n_str[plen*i:plen*(i+1)] != n_str[plen*(i+1):plen*(i+2)]
            {
                pattern_matched = false
                break
            }
            if pattern_matched
            {
                results[1] += n
                break
            }
        }
    }

    return results
}

@private // This helper function might be useful somewhere else
next_power_of_10 :: proc "contextless" (n: int) -> int
{
    if n == 0 do return 1
    p := 10
    for p <= n do p *= 10
    return p
}
