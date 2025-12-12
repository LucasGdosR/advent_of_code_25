#+private file
package aoc

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
solve_day_04_st :: proc() -> [2]int
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
                for ii in i_lb..=i_ub do for jj in j_lb..=j_ub do my_neighbors += int((M^)[ii][jj] & MASK != 0)
                (M^)[i][j] = u8((my_neighbors << 1) | 1)
            }
        }

        // Part 1
        CAN_REMOVE :: (5 << 1) | 1
        for pr_ij in prs_ij do results[0] += int((M^)[pr_ij[0]][pr_ij[1]] < CAN_REMOVE)

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

        return results
    }
    else do return [2]int{}
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

 Fixed_Point :: enum { No, Maybe, Yes }
 global_is_done: Fixed_Point
 global_results: [2]int

@private
solve_day_04_mt :: proc() -> [2]int
{
    this_idx := context.user_index

    local_results: [2]int
    M := cast(^[SIDE][SIDE+1]u8)raw_data(INPUT)

    start, end := split_count_evenly(SIDE)
    s, e := u8(start), u8(end)
    has_upper_neighbor := this_idx != 0
    has_lower_neighbor := this_idx != NUMBER_OF_CORES - 1

    // Paper rolls are split into three different dynamic arrays per thread based on their `i` coordinate.
    // This allows us to not have to use conditionals based on `i` later.
    prs_ij_ub := make([dynamic][2]u8, 0, has_upper_neighbor ? SIDE : 0)
    prs_ij    := make([dynamic][2]u8, 0, int(e - s - u8(has_lower_neighbor) - u8(has_upper_neighbor)) * SIDE)
    prs_ij_lb := make([dynamic][2]u8, 0, has_lower_neighbor ? SIDE : 0)

    // Instead of a single loop from start to end, we have one iteration of the loop for the upper bound,
    // then the middle of the range, and then an iteration for the lower bound.
    if has_upper_neighbor {
        for j in u8(0)..<SIDE do if (M^)[s][j] == '@'
        {
            append(&prs_ij_ub, [2]u8{s, j})
            my_neighbors: int
            j_lb := j == 0 ? j : j - 1
            for ii in s-1..=s+1 do for jj in j_lb..=j+1 do my_neighbors += int((M^)[ii][jj] & MASK != 0)
            (M^)[s][j] = u8((my_neighbors << 1) | 1)
        }
    }
    else do for j in u8(0)..<SIDE do if (M^)[0][j] == '@' // Might as well deal with this and get rid of `i_lb``
    {
        append(&prs_ij, [2]u8{0, j})
        my_neighbors: int
        j_lb := j == 0 ? j : j - 1
        #unroll for ii in 0..=1 do for jj in j_lb..=j+1 do my_neighbors += int((M^)[ii][jj] & MASK != 0)
        (M^)[0][j] = u8((my_neighbors << 1) | 1)
    }

    for i in s+1..<e-1 do for j in u8(0)..<SIDE do if (M^)[i][j] == '@'
    {
        append(&prs_ij, [2]u8{i, j})
        my_neighbors: int
        j_lb := j == 0 ? j : j - 1
        for ii in i-1..=i+1 do for jj in j_lb..=j+1 do my_neighbors += int((M^)[ii][jj] & MASK != 0)
        (M^)[i][j] = u8((my_neighbors << 1) | 1)
    }

    if has_lower_neighbor
    {
        for j in u8(0)..<SIDE do if (M^)[e-1][j] == '@'
        {
            append(&prs_ij_lb, [2]u8{e-1, j})
            my_neighbors: int
            j_lb := j == 0 ? j : j - 1
            for ii in e-2..=e do for jj in j_lb..=j+1 do my_neighbors += int((M^)[ii][jj] & MASK != 0)
            (M^)[e-1][j] = u8((my_neighbors << 1) | 1)
        }
    }
    else do for j in u8(0)..<SIDE do if (M^)[SIDE-1][j] == '@' // Might as well deal with this and get rid of `i_ub`
    {
        append(&prs_ij, [2]u8{SIDE-1, j})
        my_neighbors: int
        j_lb := j == 0 ? j : j - 1
        j_ub := j == SIDE-1 ? j : j + 1
        #unroll for ii in SIDE-2..=SIDE-1 do for jj in j_lb..=j_ub do my_neighbors += int((M^)[ii][jj] & MASK != 0)
        (M^)[SIDE-1][j] = u8((my_neighbors << 1) | 1)
    }

    // Part 1
    CAN_REMOVE :: (5 << 1) | 1
    for pr_ij in prs_ij_ub do local_results[0] += int((M^)[pr_ij[0]][pr_ij[1]] < CAN_REMOVE)
    for pr_ij in prs_ij    do local_results[0] += int((M^)[pr_ij[0]][pr_ij[1]] < CAN_REMOVE)
    for pr_ij in prs_ij_lb do local_results[0] += int((M^)[pr_ij[0]][pr_ij[1]] < CAN_REMOVE)
    sync.atomic_add_explicit(&global_results[0], local_results[0], sync.Atomic_Memory_Order.Relaxed)

    // Sync at this point so no paper rolls are removed while some thread is counting neighbors.
    sync.barrier_wait(&BARRIER)

    /* Part 2:
     * Each thread can freely modify neighbors of `prs_ij`, but not of `ub/lb`.
     * Neighbor count must be recomputed for every paper roll on boundaries between threads,
     * and then the cell is removed and mutates only neighbors in the thread's domain.
     */
    for//ever
    {
        prs_len := len(prs_ij) + len(prs_ij_lb) + len(prs_ij_ub)

        // Upper bounds
        for i := len(prs_ij_ub) - 1; i >= 0; i-=1
        {
            pr_i, pr_j := prs_ij_ub[i][0], prs_ij_ub[i][1]
            j_lb := pr_j == 0 ? pr_j : pr_j - 1

            my_neighbors: u8
            for ii in pr_i-1..=pr_i+1 do for jj in j_lb..=pr_j+1 do my_neighbors += (M^)[ii][jj] & 1

            if my_neighbors < 5
            {
                unordered_remove(&prs_ij_ub, i)
                (M^)[pr_i][pr_j] = 0 // Remove the paper so neighboring threads can recompute.
                local_results[1] += 1
                for jj in j_lb..=pr_j+1 do (M^)[pr_i+1][jj] -= (1 << 1) // Only decrement count from cells in thread's domain.
            }
        }

        // Thread's domain
        for i := len(prs_ij) - 1; i >= 0; i-=1
        {
            pr_i, pr_j := prs_ij[i][0], prs_ij[i][1]

            if (M^)[pr_i][pr_j] < CAN_REMOVE
            {
                unordered_remove(&prs_ij, i)
                (M^)[pr_i][pr_j] = 0 // Remove the paper so neighboring threads can recompute.
                local_results[1] += 1

                i_lb := pr_i == 0 ? pr_i : pr_i - 1
                i_ub := pr_i == SIDE - 1 ? pr_i : pr_i + 1
                j_lb := pr_j == 0 ? pr_j : pr_j - 1
                j_ub := pr_j == SIDE - 1 ? pr_j : pr_j + 1
                for ii in i_lb..=i_ub do for jj in j_lb..=j_ub do (M^)[ii][jj] -= (1 << 1)
            }
        }

        // Lower bounds
        for i := len(prs_ij_lb) - 1; i >= 0; i-=1
        {
            pr_i, pr_j := prs_ij_lb[i][0], prs_ij_lb[i][1]
            j_lb := pr_j == 0 ? pr_j : pr_j - 1

            my_neighbors: u8
            for ii in pr_i-1..=pr_i+1 do for jj in j_lb..=pr_j+1 do my_neighbors += (M^)[ii][jj] & 1

            if my_neighbors < 5
            {
                unordered_remove(&prs_ij_lb, i)
                (M^)[pr_i][pr_j] = 0 // Remove the paper so neighboring threads can recompute.
                local_results[1] += 1
                for jj in j_lb..=pr_j+1 do (M^)[pr_i-1][jj] -= (1 << 1) // Only decrement count from cells in thread's domain.
            }
        }

        // This *might* be a stopping point.
        if prs_len == len(prs_ij) + len(prs_ij_lb) + len(prs_ij_ub)
        {
            global_is_done = .Maybe
            sync.barrier_wait(&BARRIER)

            // Double check: can this thread make any changes? Check boundaries only.
            // Upper bounds
            for i := len(prs_ij_ub) - 1; i >= 0; i-=1
            {
                pr_i, pr_j := prs_ij_ub[i][0], prs_ij_ub[i][1]
                j_lb := pr_j == 0 ? pr_j : pr_j - 1

                my_neighbors: u8
                for ii in pr_i-1..=pr_i+1 do for jj in j_lb..=pr_j+1 do my_neighbors += (M^)[ii][jj] & 1

                if my_neighbors < 5
                {
                    unordered_remove(&prs_ij_ub, i)
                    (M^)[pr_i][pr_j] = 0
                    local_results[1] += 1
                    for jj in j_lb..=pr_j+1 do (M^)[pr_i+1][jj] -= (1 << 1)
                }
            }
            // Lower bounds
            for i := len(prs_ij_lb) - 1; i >= 0; i-=1
            {
                pr_i, pr_j := prs_ij_lb[i][0], prs_ij_lb[i][1]
                j_lb := pr_j == 0 ? pr_j : pr_j - 1

                my_neighbors: u8
                for ii in pr_i-1..=pr_i+1 do for jj in j_lb..=pr_j+1 do my_neighbors += (M^)[ii][jj] & 1

                if my_neighbors < 5
                {
                    unordered_remove(&prs_ij_lb, i)
                    (M^)[pr_i][pr_j] = 0
                    local_results[1] += 1
                    for jj in j_lb..=pr_j+1 do (M^)[pr_i-1][jj] -= (1 << 1)
                }
            }
            // Which memory ordering?
            if prs_len != len(prs_ij) + len(prs_ij_lb) + len(prs_ij_ub) do sync.atomic_store_explicit(&global_is_done, Fixed_Point.No, sync.Atomic_Memory_Order.Release)
            else do sync.atomic_compare_exchange_weak_explicit(&global_is_done, Fixed_Point.Maybe, Fixed_Point.Yes, sync.Atomic_Memory_Order.Acquire, sync.Atomic_Memory_Order.Relaxed)
            sync.barrier_wait(&BARRIER)

            // At this point, `global_is_done` was set to true before checking, followed by a fence.
            // If any thread made changes, it was set to false, followed by a fence.
            if global_is_done == .Yes do break
        }
        // Someone made changes, so we have not reached a fixed point. Keep going.
    }
    sync.atomic_add_explicit(&global_results[1], local_results[1], sync.Atomic_Memory_Order.Relaxed)
    sync.barrier_wait(&BARRIER)

    return this_idx == 0 ? global_results : [2]int{}
}
