#+private file
package aoc

import "base:intrinsics"
import q "core:container/queue"
import "core:strconv"
import "core:strings"

@private
solve_day_10_st :: proc() -> [2]int
{
    if context.user_index == 0
    {
        results: [2]int
        it := string(INPUT)

        // Free allocator every iteration
        context.allocator = context.temp_allocator
        for line in strings.split_lines_iterator(&it)
        {
            line := line
            fields := strings.fields(line)

            lights := parse_diagram(fields[0])
            buttons := parse_buttons(fields[1: len(fields) - 1])
            // joltage := parse_joltage(fields[len(fields) - 1])

            results[0] += bfs(lights, buttons)
            // results[1] += lp(buttons, joltage)
            free_all(context.allocator)
        }
        return results
    }
    else do return [2]int{}
}

@private
solve_day_10_mt :: proc() -> [2]int
{
    results: [2]int
    start, end := split_lines_roughly(INPUT)
    it := string(INPUT[start:end])
    context.allocator = context.temp_allocator
    for line in strings.split_lines_iterator(&it)
    {
        fields := strings.fields(line)
        lights := parse_diagram(fields[0])
        buttons := parse_buttons(fields[1: len(fields) - 1])
        results[0] += bfs(lights, buttons)
        free_all(context.allocator)
    }
    return sum_local_results(results)
}

// 0th index in LSB
parse_diagram :: proc "contextless" (s: string) -> i16
{
    target: i16
    s := s[1:len(s)-1] // Strip brackets
    for c, i in s do if c == '#' do target |= 1 << uint(i)
    return target
}

parse_buttons :: proc(ss: []string) -> []i16
{
    buttons := make([dynamic]i16)
    for button in ss
    {
        button := button[1:len(button)-1] // Strip parentheses
        split_buttons := strings.split(button, ",")
        action: i16
        for b in split_buttons
        {
            n, _ := strconv.parse_uint(b)
            action |= 1 << n
        }
        append(&buttons, action)
    }
    return buttons[:]
}

bfs :: proc(goal: i16, buttons: []i16) -> int
{
    queue: q.Queue(i32)
    q.init(&queue)
    // All actions available
    q.push_back(&queue, (1 << uint(len(buttons))) - 1)
    for
    {
        curr := q.pop_front(&queue)
        // curr:
        // curr_pattern:     actions_left:
        // xxxxxxxx xxxxxxxx yyyyyyyy yyyyyyyy
        curr_pattern := i16(curr >> 16)
        actions_left := i16(curr)
        iterator := actions_left
        for iterator != 0
        {
            // Pick LSB:
            action_idx := intrinsics.count_trailing_zeros(iterator)
            action : i16 = 1 << uint(action_idx)

            // Press button and make new pattern:
            next_pattern := curr_pattern ~ buttons[action_idx]
            // button_presses = button_count - buttons_left
            if next_pattern == goal do return len(buttons) - int(intrinsics.count_ones(actions_left) - 1) // -1 for this button press

            // Remove this action from the iterator:
            iterator ~= action

            // Pack neighboring state:
            next : i32 = (i32(next_pattern) << 16) | i32(actions_left ~ action)
            q.push_back(&queue, next)
        }
    }
}

parse_joltage :: proc(s: string) -> []int
{
    s := s[1:len(s)-1] // Strip braces
    nums := strings.split(s, ",")
    joltage := make([dynamic]int, 0, len(nums))
    for n in nums
    {
        i, _ := strconv.parse_int(n)
        append(&joltage, i)
    }
    return joltage[:]
}

lp :: proc(buttons: [][]int, joltage: []int) -> int
{
    // Odin has no linear programming solver.
    // Let's use scipy or or-tools or something.
    // Maybe I can wire some foreign calls later.
    return 0
}
