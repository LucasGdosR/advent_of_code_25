#+private file
package aoc

import "core:strconv"
import "core:strings"
import "core:sync"

LINE_BREAK :: 1
global_results: [2]int

@private
solve_day_06_st :: proc() -> Results
{
    if context.user_index == 0
    {
        results: [2]int
        data_lines, op_line := parse_lines()

        operands := make([dynamic]int, 0, 4)
        results[1] = part_2(&operands, data_lines[:], op_line, 0, len(op_line))
        results[0] = part_1(&operands, data_lines[:], &op_line)

        return make_results(results)
    }
    else do return Results{}
}

@private
solve_day_06_mt :: proc() -> Results
{
    this_id := context.user_index

    local_results: [2]int
    data_lines, op_line := parse_lines()

    // split problem roughly
    start, end := split_count_evenly(len(op_line))
    if start != 0 do for
    {
        all_blanks := true
        for line in data_lines do all_blanks &&= line[start] == ' '
        all_blanks &&= op_line[start] == ' '
        start += 1
        if all_blanks do break
    }
    if end != len(op_line) do for
    {
        all_blanks := true
        for line in data_lines do all_blanks &&= line[end] == ' '
        all_blanks &&= op_line[end] == ' '
        if all_blanks do break
        end += 1
    }

    // Part 2
    operands := make([dynamic]int, 0, 4)
    local_results[1] = part_2(&operands, data_lines[:], op_line, start, end)

    // Part 1
    for &line in data_lines do line = line[start:end]
    op_line = op_line[start:end]

    local_results[0] = part_1(&operands, data_lines[:], &op_line)
    for op in strings.fields_iterator(&op_line)
    {
        for &line in data_lines
        {
            operand, _ := strings.fields_iterator(&line)
            n, _ := strconv.parse_int(operand)
            append(&operands, n)
        }
        local_results[0] += perform_op(op[0], operands[:])
        clear(&operands)
    }

    sync.atomic_add_explicit(&global_results[0], local_results[0], sync.Atomic_Memory_Order.Relaxed)
    sync.atomic_add_explicit(&global_results[1], local_results[1], sync.Atomic_Memory_Order.Relaxed)
    sync.barrier_wait(&BARRIER)

    return this_id == 0 ? make_results(global_results) : Results{}
}

parse_lines :: proc() -> ([4]string, string)
{
    str := string(INPUT)
    chunk := (len(str) + 1) / 5

    data_lines := [?]string{
        str[:chunk-LINE_BREAK],
        str[chunk:2*chunk-LINE_BREAK],
        str[2*chunk:3*chunk-LINE_BREAK],
        str[3*chunk:4*chunk-LINE_BREAK],
    }
    op_line := str[4*chunk:]
    return data_lines, op_line
}

part_2 :: proc(operands: ^[dynamic]int, data_lines: []string, op_line: string, start, end: int) -> int
{
    result: int
    for i := end - 1; i >= start; i-=1
    {
        operand := 0
        for line in data_lines do if line[i] != ' ' do operand = operand*10 + int(line[i] - '0')
        if operand == 0 do continue
        append(operands, operand)

        op := op_line[i]
        if op != ' '
        {
            result += perform_op(op, operands[:])
            clear(operands)
        }
    }
    return result
}

part_1 :: proc(operands: ^[dynamic]int, data_lines: []string, op_line: ^string) -> int
{
    result: int
    for op in strings.fields_iterator(op_line)
    {
        for &line in data_lines
        {
            operand, _ := strings.fields_iterator(&line)
            n, _ := strconv.parse_int(operand)
            append(operands, n)
        }
        result += perform_op(op[0], operands[:])
        clear(operands)
    }
    return result
}

perform_op :: proc(op: u8, operands: []int) -> int
{
    result := 0
    if op == '+' do for o in operands do result += o
    else
    {
        result = 1
        for o in operands do result *= o
    }
    return result
}