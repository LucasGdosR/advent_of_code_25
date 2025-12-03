package aoc

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sync"

key :: struct {
    str: string,
    b: byte,
}

example_ST :: proc() -> Results
{
    // Reading input is done by a single thread, so we wrap this in an "if idx == 0" block and sync with a barrier
    LR, LR_map, starting_points := parse_input()
    l := len(LR)
    results := [2]int {0, l}

    // This problem has only 6 starting points, so we wrap this in an "if idx < len(startingPoints)", since we have more than 6 cores available
    for start in starting_points
    {
        count := 0
        curr := start
        for curr[2] != 'Z' {
            curr = LR_map[key{str=curr, b=LR[count % l]}]
            count += 1
        }
        if start == "AAA" do results[0] = count
        // This is a global variable, so we need this to be atomic
        results[1] *= count / l
    }
    // Sync and return results. It'd be fine for every thread to send the results.
    return make_results(results)
}

EXAMPLE_LR: string
EXAMPLE_LR_map: map[key]string
EXAMPLE_starting_points: []string
EXAMPLE_results: [2]int
EXAMPLE_partial_results: []int

example_MT :: proc() -> Results
{
    this_idx := context.user_index
    if this_idx == 0
    {
        EXAMPLE_LR, EXAMPLE_LR_map, EXAMPLE_starting_points = parse_input()
        EXAMPLE_partial_results = make([]int, len(EXAMPLE_starting_points))
    }
    sync.barrier_wait(&BARRIER)

    // This would need to be reworked if we had more points or fewer cores
    // It would become a for loop using split_count_evenly or something like that
    points := len(EXAMPLE_starting_points)
    if this_idx < points
    {
        l := len(EXAMPLE_LR)
        count := 0
        start := EXAMPLE_starting_points[this_idx]
        curr := start
        for curr[2] != 'Z' {
            curr = EXAMPLE_LR_map[key{str=curr, b=EXAMPLE_LR[count % l]}]
            count += 1
        }
        // This "if" only gets executed by a single thread, so it doesn't need to be atomic.
        if start == "AAA" do EXAMPLE_results[0] = count
        EXAMPLE_partial_results[this_idx] = count / l
    }
    sync.barrier_wait(&BARRIER)

    // Since there's no atomic multiply, I stored partial results and multiplied them in a single thread.
    if this_idx == 0
    {
        acc := len(EXAMPLE_LR)
        for p in EXAMPLE_partial_results do acc *= p
        EXAMPLE_results[1] = acc
    }

    if this_idx == 0 do return make_results(EXAMPLE_results)
    else do return Results{}
}

parse_input :: proc() -> (string, map[key]string, []string)
{
    file, _ := os.read_entire_file("input8")
    it := string(file)
    LR, _ := strings.split_lines_iterator(&it)
	strings.split_lines_iterator(&it)

	LR_map := make(map[key]string)
	starting_points := make([dynamic]string, 0, 6)
	for line in strings.split_lines_after_iterator(&it) {
		curr := line[:3]
        key1 := key{curr, 'L'}
        key2 := key{curr, 'R'}
		LR_map[key1] = line[7:10]
		LR_map[key2] = line[12:15]
		if line[2] == 'A' {
            append(&starting_points, curr)
		}
	}
	return LR, LR_map, starting_points[:]
}