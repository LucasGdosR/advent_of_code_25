#+private file
package aoc

import "core:fmt"
import "core:sync"

SIDE :: 139
PAPER_ROLL_TOTAL :: 12_563 // SIDE * SIDE would also be fine
/******************************
 * '@'  == 0100 0000
 * '.'  == 0010 1110
 * '\n' == 0000 1010
 * MASK == 1101 0001
 *
 * MASK matches both '@' and the first bit,
 * so use the first bit for flagging paper rolls,
 * and store neighbor count in the following bits.
 ******************************/
MASK :: ~(u8('.') | u8('\n'))

@private
solve_day_04_st :: proc() -> Results
{
    if context.user_index == 0
    {
        results: [2]int

        // Cast input to be able to index into it.
        M := cast(^[SIDE][SIDE+1]u8)raw_data(INPUT)
        // List to avoid iterating over the whole matrix searching for papers to remove.
        prs_ij := make([dynamic][2]u8, 0, PAPER_ROLL_TOTAL)

        // Fill list and mutate matrix:
        for i in u8(0)..<SIDE
        {
            i_lb := i == 0 ? i : i - 1
            i_ub := i == SIDE - 1 ? i : i + 1
            for j in u8(0)..<SIDE do if (M^)[i][j] == '@'
            {
                append(&prs_ij, [2]u8{i, j})
                my_neighbors: int
                j_lb := j == 0 ? j : j - 1
                j_ub := j == SIDE - 1 ? j : j + 1
                for ii in i_lb..=i_ub do for jj in j_lb..=j_ub do if ii != i || jj != j do my_neighbors += int((M^)[ii][jj] & MASK != 0)
                (M^)[i][j] = u8((my_neighbors << 1) | 1)
            }
        }

        // Part 1
        CAN_REMOVE :: (4 << 1) | 1
        for pr_ij in prs_ij do if (M^)[pr_ij[0]][pr_ij[1]] < CAN_REMOVE do results[0] += 1

        // Part 2
        for//ever
        {
            prs_len := len(prs_ij)
            for i := prs_len - 1; i >= 0; i-=1
            {
                pr_i, pr_j := prs_ij[i][0], prs_ij[i][1]

                if (M^)[pr_i][pr_j] < CAN_REMOVE
                {
                    unordered_remove(&prs_ij, i)
                    results[1] += 1

                    i_lb := pr_i == 0 ? pr_i : pr_i - 1
                    i_ub := pr_i == SIDE - 1 ? pr_i : pr_i + 1
                    j_lb := pr_j == 0 ? pr_j : pr_j - 1
                    j_ub := pr_j == SIDE - 1 ? pr_j : pr_j + 1
                    for ii in i_lb..=i_ub do for jj in j_lb..=j_ub do (M^)[ii][jj] -= (1 << 1) // Never flip the first bit!
                }
            }
            if prs_len == len(prs_ij) do break
        }

        return make_results(results)
    }
    else do return Results{}
}

/******************************************************************************************
 * This problem has a fixed-point solution: keep iterating until there are no more changes.
 *
 * Fixed-point algorithms are tricky for multithreading. One thread might not see changes,
 * but another might make some changes that allow the other to eventually have more changes
 * later.
 *
 * My solution to this problem is to have all threads propose they are done, and then double
 * check. It is a lot like 2 Phase Commit (2PC). By double checking afterwards, we know that
 * the thread's neighbors could not make any more changes on their own, and we must confirm
 * that the thread also cannot. If some thread could make changes, then it might have enabled
 * neighbors to make changes, so they must check again.
 *
 * Changes regarding the single threaded implementation are commented. Repeated code is not.
 ******************************************************************************************/

global_results: [2]int
global_might_be_done: []bool
global_is_done: []bool

@private
solve_day_04_mt :: proc() -> Results
{
    this_idx := context.user_index
    if this_idx == 0
    {
        global_might_be_done = make([]bool, NUMBER_OF_CORES)
        global_is_done = make([]bool, NUMBER_OF_CORES)
    }

    local_results: [2]int
    M := cast(^[SIDE][SIDE+1]u8)raw_data(INPUT)

    start, end := split_count_evenly(SIDE)
    s, e := u8(start), u8(end)
    has_upper_neighbor := this_idx != 0
    has_lower_neighbor := this_idx != NUMBER_OF_CORES - 1

    // Paper rolls are split into three different dynamic arrays per thread based on their `i` coordinate.
    // This allows us to not have to use conditionals based on `i` later.
    prs_ij_upper_bound := make([dynamic][3]u8, 0, has_upper_neighbor ? SIDE : 0)
    prs_ij := make([dynamic][3]u8, 0, int(e - s - u8(has_lower_neighbor) - u8(has_upper_neighbor)) * SIDE)
    prs_ij_lower_bound := make([dynamic][3]u8, 0, has_lower_neighbor ? SIDE : 0)

    // Instead of a single loop from start to end, we have one iteration of the loop for the upper bound,
    // then the middle of the range, and then an iteration for the lower bound.
    if has_upper_neighbor {
        for j in u8(0)..<SIDE do if (M^)[s][j] == '@'
        {
            my_neighbors: int
            j_lb := j == 0 ? j : j - 1
            for i in s-1..=s+1 do for jj in j_lb..=j+1 do if i != s || jj != j do my_neighbors += int((M^)[i][jj] == '@')
            append(&prs_ij_upper_bound, [3]u8{s, j, u8(my_neighbors)})
        }
    }
    else do for j in u8(0)..<SIDE do if (M^)[0][j] == '@' // Might as well deal with this and get rid of `i_lb``
    {
        my_neighbors: int
        j_lb := j == 0 ? j : j - 1
        #unroll for i in 0..=1 do for jj in j_lb..=j+1 do if i != 0 || jj != j do my_neighbors += int((M^)[i][jj] == '@')
        append(&prs_ij, [3]u8{0, j, u8(my_neighbors)})
    }

    for i in s+1..<e-1 do for j in u8(0)..<SIDE do if (M^)[i][j] == '@'
    {
        my_neighbors: int
        j_lb := j == 0 ? j : j - 1
        for ii in i-1..=i+1 do for jj in j_lb..=j+1 do if ii != i || jj != j do my_neighbors += int((M^)[ii][jj] == '@')
        append(&prs_ij, [3]u8{i, j, u8(my_neighbors)})
    }

    if has_lower_neighbor
    {
        for j in u8(0)..<SIDE do if (M^)[e-1][j] == '@'
        {
            my_neighbors: int
            j_lb := j == 0 ? j : j - 1
            for i in e-2..=e do for jj in j_lb..=j+1 do if i != e-1 || jj != j do my_neighbors += int((M^)[i][jj] == '@')
            append(&prs_ij_lower_bound, [3]u8{e-1, j, u8(my_neighbors)})
        }
    }
    else do for j in u8(0)..<SIDE do if (M^)[SIDE-1][j] == '@' // Might as well deal with this and get rid of `i_ub`
    {
        my_neighbors: int
        j_lb := j == 0 ? j : j - 1
        j_ub := j == SIDE-1 ? j : j + 1
        #unroll for i in SIDE-2..=SIDE-1 do for jj in j_lb..=j_ub do if i != SIDE-1 || jj != j do my_neighbors += int((M^)[i][jj] == '@')
        append(&prs_ij, [3]u8{SIDE-1, j, u8(my_neighbors)})
    }

    // Part 1
    for pr_ij in prs_ij_upper_bound do if pr_ij[2] < 4 do local_results[0] += 1
    for pr_ij in prs_ij             do if pr_ij[2] < 4 do local_results[0] += 1
    for pr_ij in prs_ij_lower_bound do if pr_ij[2] < 4 do local_results[0] += 1
    sync.atomic_add_explicit(&global_results[0], local_results[0], sync.Atomic_Memory_Order.Relaxed)

    // Part 2
    sync.barrier_wait(&BARRIER) // Ensure globals were made by thread 0.
    fmt.println(global_results[0])
    // TODO

    /*
     * This is where most changes need to happen.
     * Each thread can only modify
     */
    for//ever
    {
        prs_len := len(prs_ij)
        for i := prs_len - 1; i >= 0; i-=1
        {
            pr_i, pr_j := prs_ij[i][0], prs_ij[i][1]

            if (M^)[pr_i][pr_j] < 4
            {
                unordered_remove(&prs_ij, i)
                (M^)[pr_i][pr_j] = 0 // Remove the paper so neighboring threads can recompute.
                local_results[1] += 1

                i_lb := pr_i == 0 ? pr_i : pr_i - 1
                i_ub := pr_i == SIDE - 1 ? pr_i : pr_i + 1
                j_lb := pr_j == 0 ? pr_j : pr_j - 1
                j_ub := pr_j + 1
                for ii in i_lb..=i_ub do for jj in j_lb..=j_ub do (M^)[ii][jj] -= (1 << 1) // Never flip the first bit!
            }
        }
        if prs_len == len(prs_ij) do break
        break
    }


    return this_idx == 0 ? make_results(global_results) : Results{}
}