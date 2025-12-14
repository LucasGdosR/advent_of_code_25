#+private file
package aoc

import "core:strconv"
import "core:strings"

RED_HERRING :: 96
LINE_SPLIT :: 7

@private
solve_day_12_st :: proc() -> [2]int
{
    if context.user_index == 0
    {
        result: int
        it := string(INPUT[RED_HERRING:])
        for line in strings.split_lines_iterator(&it)
        {
            line := line
            W, _ := strconv.parse_int(line[:2])
            H, _ := strconv.parse_int(line[3:5])
            line = line[LINE_SPLIT:]
            shapes_sum: int
            for shape_count in strings.fields_iterator(&line)
            {
                count, _ := strconv.parse_int(shape_count)
                shapes_sum += count
            }
            if W * H >= shapes_sum * 9 do result += 1
        }
        return [2]int{ result, 0 }
    }
    else do return [2]int{}
}

@private
solve_day_12_mt :: proc() -> [2]int
{
    results: [2]int
    start, end := split_lines_roughly(INPUT[RED_HERRING:])
    it := string(INPUT[RED_HERRING + start : RED_HERRING + end])
    for line in strings.split_lines_iterator(&it)
    {
        line := line
        W, _ := strconv.parse_int(line[:2])
        H, _ := strconv.parse_int(line[3:5])
        line = line[LINE_SPLIT:]
        shapes_sum: int
        for shape_count in strings.fields_iterator(&line)
        {
            count, _ := strconv.parse_int(shape_count)
            shapes_sum += count
        }
        if W * H >= shapes_sum * 9 do results += 1
    }
    return sum_local_results(results)
}
