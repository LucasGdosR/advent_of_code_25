#+private file
package aoc

import q "core:container/queue"
import "core:strconv"
import "core:strings"
import "core:sync"

@private
solve_day_10_st :: proc() -> Results
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

            // Make light_diagram a target
            lights := parse_diagram(fields[0])
            buttons := parse_buttons(fields[1: len(fields) - 1])
            // joltage := parse_joltage(fields[len(fields) - 1])

            results[0] += bfs(lights, buttons)
            // results[1] += lp(buttons, joltage)
            free_all(context.allocator)
        }
        return make_results(results)
    }
    else do return Results{}
}

global_results: [2]int

@private
solve_day_10_mt :: proc() -> Results
{
    local_result: int
    start, end := split_lines_roughly(INPUT)
    it := string(INPUT[start:end])
    context.allocator = context.temp_allocator
    for line in strings.split_lines_iterator(&it)
    {
        line := line
        fields := strings.fields(line)
        lights := parse_diagram(fields[0])
        buttons := parse_buttons(fields[1: len(fields) - 1])
        local_result += bfs(lights, buttons)
        free_all(context.allocator)
    }
    sync.atomic_add_explicit(&global_results[0], local_result, sync.Atomic_Memory_Order.Relaxed)
    sync.barrier_wait(&BARRIER)
    return context.user_index == 0 ? make_results(global_results) : Results{}
}

// 0th index in LSB
parse_diagram :: proc "contextless" (s: string) -> int
{
    target: int
    s := s[1:len(s)-1] // Strip brackets
    for c, i in s do if c == '#' do target |= 1 << uint(i)
    return target
}

parse_buttons :: proc(ss: []string) -> []int
{
    buttons := make([dynamic]int)
    for button in ss
    {
        button := button[1:len(button)-1] // Strip parentheses
        split_buttons := strings.split(button, ",")
        action: int
        for b in split_buttons
        {
            n, _ := strconv.parse_uint(b)
            action |= 1 << n
        }
        append(&buttons, action)
    }
    return buttons[:]
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

bfs :: proc(goal: int, buttons: []int) -> int
{
    queue: q.Queue([2]int)
    q.init(&queue)
    q.push_back(&queue, [2]int{})

    for
    {
        curr := q.pop_front(&queue)
        moves := curr[1] + 1
        for b in buttons
        {
            new_state := curr[0] ~ b // ~ is XOR
            if new_state == goal do return moves
            q.push_back(&queue, [2]int{ new_state, moves })
        }
    }
}

lp :: proc(buttons: [][]int, joltage: []int) -> int
{
    // Odin has no linear programming solver.
    // Let's use scipy or or-tools or something.
    // Maybe I can wire some foreign calls later.
    return 0
}
