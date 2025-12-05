#+private file
package aoc

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
                j_ub := j + 1 // Line break sentinel is fine to add
                for ii in i_lb..=i_ub do for jj in j_lb..=j_ub do if ii != i || jj != j do my_neighbors += int((M^)[ii][jj] & MASK != 0)
                (M^)[i][j] = u8((my_neighbors << 1) | 1)
            }
        }

        // Part 1
        CAN_REMOVE :: (4 << 1) | 1
        for pr_ij in prs_ij do if (M^)[pr_ij[0]][pr_ij[1]] < CAN_REMOVE do results[0] += 1

        // Part 2
        for
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
                    j_ub := pr_j + 1
                    for ii in i_lb..=i_ub do for jj in j_lb..=j_ub do (M^)[ii][jj] -= (1 << 1) // Never flip the first bit!
                }
            }
            if prs_len == len(prs_ij) do break
        }

        return make_results(results)
    }
    else do return Results{}
}

solve_day_04_mt :: proc() -> Results
{
    return Results{}
}