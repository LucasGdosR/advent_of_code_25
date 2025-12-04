package aoc

import "core:os"
import "core:strconv"
import "core:strings"

solve_day_01 :: proc() -> Results
{
    if context.user_index == 0
    {
        results: [2]int
        curr := 50
        input, ok := os.read_entire_file("input/01")
        if !ok do os.exit(1)
        it := string(input)

        for line in strings.split_lines_iterator(&it)
        {
            sign := line[0] == 'L' ? -1 : 1
            rot, _ := strconv.parse_int(line[1:])
            next := curr + sign * rot
            results[1] += abs(next) / 100 + int(next == 0 || (next < 0 && curr > 0))
            curr = next %% 100
            results[0] += int(curr == 0)
        }
        return make_results(results)
    }
    else do return Results{}
}
