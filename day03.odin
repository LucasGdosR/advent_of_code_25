#+private file
package aoc

import "core:strings"

BANK_LEN :: 100
LINE_WIDTH :: BANK_LEN + 1 // '\n'
LINE_COUNT :: 200

@private
solve_day_03_st :: proc() -> [2]int
{
    if context.user_index == 0 do return solve(string(INPUT))
    else do return [2]int{}
}

@private
solve_day_03_mt :: proc() -> [2]int
{
    start_row, end_row := split_count_evenly(LINE_COUNT)
    start_i, end_i := start_row * LINE_WIDTH, end_row * LINE_WIDTH - int(context.user_index == NUMBER_OF_CORES - 1)
    results := solve(string(INPUT[start_i:end_i]))
    return sum_local_results(results)
}

solve :: proc(it: string) -> [2]int
{
    it := it
    results: [2]int
    stack := make([dynamic]rune, 0, 100)
    for bank in strings.split_lines_iterator(&it)
    {
        assert(len(bank) == BANK_LEN, "Unexpected input dimensions. Line size is hard coded.")
        first_digit: rune
        first_digit_idx := 0
        for c, i in bank
        {
            // Part 1
            if i < len(bank) - 1 && c > first_digit do first_digit, first_digit_idx = c, i

            // Part 2:
            // Keep the highest number at the bottom of the stack
            // as long as there are enough elements left to fill it to 12.
            for len(stack) > 0 && c > stack[len(stack) - 1] && BANK_LEN - i - 1 >= 12 - len(stack) do pop(&stack)
            append(&stack, c)
        }

        // Part 1
        second_digit: rune
        for c in bank[first_digit_idx+1:] do second_digit = max(second_digit, c)
        results[0] += 10 * int(first_digit - '0') + int(second_digit) - '0'

        // Part 2:
        multiplier := 1
        for i := 11; i >= 0; i-=1
        {
            results[1] += multiplier * int(stack[i] - '0')
            multiplier *= 10
        }
        clear(&stack)
    }
    return results
}
