#+private file
package aoc

import "core:sync"
import q "core:container/queue"
import "core:slice"
import "core:strconv"
import "core:strings"

@private
solve_day_10_st :: proc() -> Results
{
    if context.user_index == 0
    {
        results: [2]int
        it := string(INPUT)

        // Free allocator every iteration
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
    for line in strings.split_lines_iterator(&it)
    {
        line := line
        fields := strings.fields(line)
        lights := parse_diagram(fields[0])
        buttons := parse_buttons(fields[1: len(fields) - 1])
        local_result += bfs(lights, buttons)
    }
    sync.atomic_add_explicit(&global_results[0], local_result, sync.Atomic_Memory_Order.Relaxed)
    sync.barrier_wait(&BARRIER)
    return context.user_index == 0 ? make_results(global_results) : Results{}
}

parse_diagram :: proc(s: string) -> []bool
{
    s := s[1:len(s)-1] // Strip brackets
    lights := make([dynamic]bool, 0, len(s))
    for c in s do append(&lights, c == '#')
    return lights[:]
}

parse_buttons :: proc(ss: []string) -> [][]int
{
    buttons := make([dynamic][]int)
    for button in ss
    {
        button := button[1:len(button)-1] // Strip parentheses
        split_buttons := strings.split(button, ",")
        array := make([dynamic]int, 0, len(split_buttons))
        for b in split_buttons
        {
            n, _ := strconv.parse_int(b)
            append(&array, n)
        }
        append(&buttons, array[:])
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

E :: struct
{
    lights: []bool,
    moves: int,
}

bfs :: proc(goal: []bool, buttons: [][]int) -> int
{
    context.allocator = context.temp_allocator
    defer free_all(context.allocator)

    start := make([]bool, len(goal))
    queue: q.Queue(E)
    q.init(&queue)
    q.push_back(&queue, E{ lights=start, moves=0 })

    for
    {
        curr := q.pop_front(&queue)
        moves := curr.moves + 1
        for b in buttons
        {
            new_state := make([]bool, len(goal))
            copy(new_state, curr.lights)
            for i in b do new_state[i] = !new_state[i]
            if slice.simple_equal(new_state, goal) do return moves
            q.push_back(&queue, E{ new_state, moves })
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
