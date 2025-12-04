#+private file
package aoc

import "core:os"
import "core:strings"
import "core:sync"

global_input: []byte
global_results: [2]int
BANK_LEN :: 100
LINE_WIDTH :: BANK_LEN + 1 // '\n'
LINE_COUNT :: 200

@private
solve_day_03 :: proc() -> Results
{
    this_idx := context.user_index
    if context.user_index == 0
    {
        ok: bool
        global_input, ok = os.read_entire_file("input/03")
        if !ok do os.exit(1)
    }

    local_results: [2]int
    stack := make([dynamic]rune, 0, 100)

    sync.barrier_wait(&BARRIER)

    start_row, end_row := split_count_evenly(LINE_COUNT)
    start_i, end_i := start_row * LINE_WIDTH, end_row * LINE_WIDTH - int(this_idx == NUMBER_OF_CORES - 1)
    it := string(global_input[start_i:end_i])

    for bank in strings.split_lines_iterator(&it)
    {
        assert(len(bank) == BANK_LEN, "Unexpected input dimensions. Line size is hard coded.")
        first_digit: rune
        first_digit_idx := 0
        for c, i in bank
        {
            // Part 1
            if i < BANK_LEN - 1 && c > first_digit do first_digit, first_digit_idx = c, i

            // Part 2:
            // Keep the highest number at the bottom of the stack
            // as long as there are enough elements left to fill it to 12.
            for len(stack) > 0 && c > stack[len(stack) - 1] && BANK_LEN - i - 1 >= 12 - len(stack) do pop(&stack)
            append(&stack, c)
        }

        // Part 1
        second_digit: rune
        for c in bank[first_digit_idx+1:] do second_digit = max(second_digit, c)
        local_results[0] += 10 * int(first_digit - '0') + int(second_digit) - '0'

        // Part 2:
        multiplier := 1
        for i := 11; i >= 0; i-=1
        {
            local_results[1] += multiplier * int(stack[i] - '0')
            multiplier *= 10
        }
        clear(&stack)
    }
    sync.atomic_add_explicit(&global_results[0], local_results[0], sync.Atomic_Memory_Order.Relaxed)
    sync.atomic_add_explicit(&global_results[1], local_results[1], sync.Atomic_Memory_Order.Relaxed)

    sync.barrier_wait(&BARRIER)

    return this_idx == 0 ? make_results(global_results) : Results{}
}
