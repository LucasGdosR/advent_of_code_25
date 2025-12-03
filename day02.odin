package aoc

import "core:os"
import "core:strconv"
import "core:strings"
import "core:sync"

INTERVALS :: 38

DAY02_intervals: [][2]string
DAY02_results: [2]int
DAY02_task_counter: int

solve_day_02 :: proc() -> Results
{
    this_idx := context.user_index
    if this_idx == 0 do make_intervals()

    local_results: [2]int
    start_local_buffer: [16]byte
    end_local_buffer: [16]byte

    sync.barrier_wait(&BARRIER)

    interval_count := len(DAY02_intervals)

    for//ever
    {
        interval_idx := sync.atomic_add_explicit(&DAY02_task_counter, 1, sync.Atomic_Memory_Order.Relaxed)
        if interval_idx >= interval_count do break

        interval := DAY02_intervals[interval_idx]
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
            right_start := strconv.atoi(start[length  / 2 :])
            right_end := strconv.atoi(end[(length + int(start_is_odd)) / 2 :])
            if same_length do left_interval = { strconv.atoi(start[:length/2]), strconv.atoi(end[:length/2]) }
            // Start is odd, so increase it to the next power of 10
            else if start_is_odd
            {
                left_interval = { next_power_of_10(strconv.atoi(start[:length/2])), strconv.atoi(end[:(length+1)/2]) }
                right_start = 0
            }
            else // End is odd, so shift it to (the next power of 10 after start) - 1
            {
                lstart := strconv.atoi(start[:length/2])
                left_interval = { lstart, next_power_of_10(lstart) - 1 }
                right_end = left_interval[1]
            }

            // There's a single number to try
            if left_interval[0] == left_interval[1]
            {
                n := left_interval[0]
                if right_start <= n && right_end >= n do local_results[0] += n + n * next_power_of_10(n)
            }
            else
            {
                p10 := next_power_of_10(left_interval[0])
                if right_start <= left_interval[0] do local_results[0] += left_interval[0] + left_interval[0] * p10
                if right_end >= left_interval[1] do local_results[0] += left_interval[1] + left_interval[1] * p10
                for i in left_interval[0]+1..=left_interval[1]-1 do local_results[0] += i + i * p10
            }
        }

        // Part 2:
        max_pattern_length := len(end) / 2
        s := strconv.atoi(start)
        e := strconv.atoi(end)
        buffer := make([]u8, 16)
        // For every number in the range s-e
        for n in s..=e
        {
            n_str := strconv.itoa(buffer, n)
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
                    local_results[1] += n
                    break
                }
            }
        }
    }
    sync.atomic_add_explicit(&DAY02_results[0], local_results[0], sync.Atomic_Memory_Order.Relaxed)
    sync.atomic_add_explicit(&DAY02_results[1], local_results[1], sync.Atomic_Memory_Order.Relaxed)

    sync.barrier_wait(&BARRIER)
    return this_idx == 0 ? make_results(DAY02_results) : Results{}
}

next_power_of_10 :: proc(n: int) -> int
{
    if n == 0 do return 1
    p := 10
    for p <= n do p *= 10
    return p
}

make_intervals :: proc()
{
    input, ok := os.read_entire_file("input/02")
    if !ok do os.exit(1)
    it := string(input)

    dyn_arr := make([dynamic][2]string, 0, INTERVALS)

    for range in strings.split_iterator(&it, ",")
    {
        range := range
        start, _ := strings.split_iterator(&range, "-")
        end := range
        append(&dyn_arr, [2]string{start, end})
    }

    DAY02_intervals = dyn_arr[:]
}
