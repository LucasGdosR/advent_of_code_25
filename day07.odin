#+private file
package aoc

import "core:strings"

HEIGHT :: 142
WIDTH :: 141
LINE_BREAK :: 1
LINE_WIDTH :: WIDTH + LINE_BREAK

@private
solve_day_07_st :: proc() -> Results
{
    if context.user_index == 0
    {
        start_j :: WIDTH / 2
        assert(INPUT[start_j] == 'S')
        grid := cast(^[HEIGHT][LINE_WIDTH]byte)raw_data(INPUT)
        TOTAL_BEAM_SPLITTERS :: 1721
        LOAD_FACTOR :: 0.75
        CAPACITY :: int((TOTAL_BEAM_SPLITTERS / LOAD_FACTOR) + 1)
        memo := make(map[u16]int, CAPACITY)
        result_part_2 := dfs(grid, &memo, 2, start_j)
        return make_results([2]int{ len(memo), result_part_2 })
    }
    else do return Results{}
}

dfs :: proc(grid: ^[HEIGHT][LINE_WIDTH]byte, memo: ^map[u16]int, i, j: u16) -> int
{
    // Find a beam splitter or exit the grid.
    bi: u16
    for bi = i; bi < HEIGHT && grid[bi][j] != '^'; bi += 2 {}

    // Base cases:
    // We've exited the end of the grid.
    if bi >=HEIGHT do return 1

    // This is a beam splitter.
    key := (bi << 8) | j

    // Already memoized this beam splitter.
    if result, ok := memo[key]; ok do return result

    // Recursive case.
    // Multithreading could be added here by spawning another thread for one of the recursive calls and using a concurrent hashmap.
    result := dfs(grid, memo, bi + 2, j - 1) + dfs(grid, memo, bi + 2, j + 1)
    memo[key] = result
    return result
}

@private
solve_day_07_mt :: proc() -> Results
{
    return Results{}
}
