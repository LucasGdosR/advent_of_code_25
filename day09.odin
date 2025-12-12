#+private file
package aoc

import "core:slice"
import "core:strconv"
import "core:strings"
import "core:sync"

line :: struct { start, end, constant: int }

global_HL: []line
global_VL: []line

@private
solve_day_09_st :: proc() -> [2]int
{
    if context.user_index == 0
    {
        results: [2]int

        points := read_points()
        global_HL, global_VL = draw_lines(points)

        // Try all pairs
        for i in 0..<len(points)-1 do for p2 in points[i+1:]
        {
            p1 := points[i]
            area := (abs(p1.x - p2.x) + 1) * (abs(p1.y - p2.y) + 1)
            if area > results[0] do results[0] = area
            if area > results[1] && is_valid(p1, p2) do results[1] = area
        }

        return results
    }
    else do return [2]int{}
}

global_points: [][2]int
global_results: [][2]int

@private
solve_day_09_mt :: proc() -> [2]int
{
    this_idx := context.user_index
    local_results: [2]int
    if this_idx == 0
    {
        global_results = make([][2]int, NUMBER_OF_CORES)
        global_points = read_points()
        // Drawing lines could be done in parallel.
        global_HL, global_VL = draw_lines(global_points)
        split_linear_work(len(global_points))
    }

    sync.barrier_wait(&BARRIER)

    start, end := global_starts_ends[this_idx], global_starts_ends[this_idx+1]
    for i in start..<end do for p2 in global_points[i+1:]
    {
        p1 := global_points[i]
        area := (abs(p1.x - p2.x) + 1) * (abs(p1.y - p2.y) + 1)
        if area > local_results[0] do local_results[0] = area
        if area > local_results[1] && is_valid(p1, p2) do local_results[1] = area
    }
    global_results[this_idx] = local_results

    sync.barrier_wait(&BARRIER)

    if this_idx == 0
    {
        results: [2]int
        for res in global_results
        {
            if res[0] > results[0] do results[0] = res[0]
            if res[1] > results[1] do results[1] = res[1]
        }
        return results
    }
    else do return [2]int{}
}

read_points :: proc() -> [][2]int
{
    it := string(INPUT)
    INPUT_LINES :: 496
    // Starting capacity is an optimization that does not reduce generality.
    points := make([dynamic][2]int, 0, INPUT_LINES)
    for coordinates in strings.split_lines_iterator(&it)
    {
        coordinates := coordinates
        x, _ := strings.split_iterator(&coordinates, ",")
        y := coordinates
        x_int, _ := strconv.parse_int(x)
        y_int, _ := strconv.parse_int(y)
        append(&points, [2]int{ x_int, y_int })
    }
    return points[:]
}

draw_lines :: proc(points: [][2]int) -> ([]line, []line)
{
    vertical_lines := make([dynamic]line, 0, len(points) / 2)
    horizontal_lines := make([dynamic]line, 0, len(points) / 2)
    for i in 1..<len(points)
    {
        p1, p2 := points[i-1], points[i]
        if p1.x == p2.x do append(&vertical_lines, draw_vertical_line(p1, p2))
        else do append(&horizontal_lines, draw_horizontal_line(p1, p2))
    }
    // Repeat the last point connecting to the first
    p1, p2 := points[len(points) - 1], points[0]
    if p1.x == p2.x do append(&vertical_lines, draw_vertical_line(p1, p2))
    else do append(&horizontal_lines, draw_horizontal_line(p1, p2))

    // Sort lines by start coordinates.
    slice.sort_by(horizontal_lines[:], proc(i, j: line) -> bool {
        return i.start < j.start
    })
    slice.sort_by(vertical_lines[:], proc(i, j: line) -> bool {
        return i.start < j.start
    })

    return horizontal_lines[:], vertical_lines[:]
}

draw_vertical_line :: proc "contextless" (p1, p2: [2]int) -> line
{
    return line{
        start=min(p1.y, p2.y),
        end=max(p1.y, p2.y),
        constant=p1.x
    }
}

draw_horizontal_line :: proc "contextless" (p1, p2: [2]int) ->line
{
    return line{
        start=min(p1.x, p2.x),
        end=max(p1.x, p2.x),
        constant=p1.y
    }
}

is_valid :: proc "contextless" (p1, p2: [2]int) -> bool
{
    // Draw rectangle borders
    min_x := min(p1.x, p2.x)
    max_x := max(p1.x, p2.x)
    min_y := min(p1.y, p2.y)
    max_y := max(p1.y, p2.y)

    for H in global_HL
    {
        // Check for interior lines
        if H.constant < max_y && H.constant > min_y && H.start > min_x && H.end < max_x ||
        // Intercept left side
        H.start < min_x && H.end > min_x && min_y < H.constant && max_y > H.constant ||
        // Intercept right side
        H.start < max_x && H.end > max_x && min_y < H.constant && max_y > H.constant
        {
             return false
        }
    }
    for V in global_VL
    {
        // Check for interior lines
        if V.constant < max_x && V.constant > min_x && V.start > min_y && V.end < max_y ||
        // Intercept north side
        V.start < max_y && V.end > max_y && min_x < V.constant && max_x > V.constant ||
        // Intercept south side
        V.start < min_y && V.end > min_y && min_x < V.constant && max_x > V.constant
        {
            return false
        }
    }

    return within_polygon(center(p1, p2))
}

center :: proc "contextless" (p1, p2: [2]int) -> [2]int { return [2]int{ (p1.x+p2.x)/2, (p1.y+p2.y)/2 } }

within_polygon :: proc "contextless" (p: [2]int) -> bool
{
    // Ray casting (to the left). Must cross an odd number of lines to be within.
    crossings: int
    // Half-open intervals [start, end) avoid double counting.
    for V in global_VL do if p.y >= V.start && p.y < V.end && V.constant < p.x do crossings += 1
    return crossings % 2 == 1
}
