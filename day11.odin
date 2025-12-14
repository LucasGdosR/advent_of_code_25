#+private file
package aoc

import "core:strings"
import "core:sync"

@private
solve_day_11_st :: proc() -> [2]int
{
    if context.user_index == 0
    {
        results: [2]int
        G := build_graph()
        memo := make(map[[2]string]int)
        // Part 1
        results[0] = dfs(G, "you", "out", &memo)
        clear(&memo)
        // Part 2
        svr_dac := dfs(G, "svr", "dac", &memo)
        clear(&memo)
        svr_fft := dfs(G, "svr", "fft", &memo)
        clear(&memo)
        fft_dac := dfs(G, "fft", "dac", &memo)
        clear(&memo)
        dac_fft := dfs(G, "dac", "fft", &memo)
        clear(&memo)
        dac_out := dfs(G, "dac", "out", &memo)
        clear(&memo)
        fft_out := dfs(G, "fft", "out", &memo)
        results[1] = svr_dac * dac_fft * fft_out + svr_fft * fft_dac * dac_out

        return results
    }
    else do return [2]int{}
}

global_G: map[string][]string
global_svr_dac: int
global_svr_fft: int
global_fft_dac: int
global_dac_fft: int
global_dac_out: int
global_fft_out: int

@private
solve_day_11_mt :: proc() -> [2]int
{
    assert(NUMBER_OF_CORES >= 7, "Day 11 assumes at least 7 threads exist.")
    this_idx := context.user_index
    local_results: [2]int
    if this_idx == 0
    {
        global_G = build_graph()
        sync.atomic_store_explicit(&INPUT_PARSED, true, .Release)
    }
    for !sync.atomic_load_explicit(&INPUT_PARSED, .Acquire) {}
    if this_idx <= 6
    {
        memo := make(map[[2]string]int)
        switch this_idx
        {
            case 0: local_results[0] = dfs(global_G, "you", "out", &memo)
            case 1: global_svr_dac = dfs(global_G, "svr", "dac", &memo)
            case 2: global_svr_fft = dfs(global_G, "svr", "fft", &memo)
            case 3: global_fft_dac = dfs(global_G, "fft", "dac", &memo)
            case 4: global_dac_fft = dfs(global_G, "dac", "fft", &memo)
            case 5: global_dac_out = dfs(global_G, "dac", "out", &memo)
            case 6: global_fft_out = dfs(global_G, "fft", "out", &memo)
        }
    }
    sync.barrier_wait(&BARRIER)
    if this_idx == 0
    {
        local_results[1] = global_svr_dac * global_dac_fft * global_fft_out + global_svr_fft * global_fft_dac * global_dac_out
        return local_results
    }
    else do return [2]int{}
}

build_graph :: proc() -> map[string][]string
{
    it := string(INPUT)
    adj_list := make(map[string][]string)
    for line in strings.split_lines_iterator(&it)
    {
        line := line
        src, _ := strings.split_iterator(&line, ": ")
        dsts := make([dynamic]string)
        for dst in strings.split_iterator(&line, " ") do append(&dsts, dst)
        adj_list[src] = dsts[:]
    }
    return adj_list
}

dfs :: proc(G: map[string][]string, curr, goal: string, memo: ^map[[2]string]int) -> int
{
    if curr == goal do return 1
    result: int
    for neighbor in G[curr]
    {
        edge := [2]string{curr, neighbor}
        if edge in memo do result += memo[edge]
        else
        {
            res := dfs(G, neighbor, goal, memo)
            memo[edge] = res
            result += res
        }
    }
    return result
}