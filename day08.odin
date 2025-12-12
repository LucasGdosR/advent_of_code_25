#+private file
package aoc

import pq "core:container/priority_queue"
import "core:strconv"
import "core:strings"
import "core:sync"

INPUT_LEN :: 1000

uf :: struct
{
    arrs: [][2]int,
    size: int,
}

@private
solve_day_08_st :: proc() -> [2]int
{
    if context.user_index == 0
    {
        junction_boxes := read_graph_vertices()
        length := len(junction_boxes)

        // Make weighted graph edges (fully connected graph).
        edges := make([dynamic][3]int, length * (length - 1) / 2)
        fill_edges(edges[:], junction_boxes, 0, length)

        return kruskal_mst(junction_boxes, edges)
    }
    else do return [2]int{}
}

global_V: [][3]int
global_E: [dynamic][3]int

@private
solve_day_08_mt :: proc() -> [2]int
{
    this_idx := context.user_index
    if this_idx == 0
    {
        global_V = read_graph_vertices()
        length := len(global_V)
        assert(length == INPUT_LEN)
        global_E = make([dynamic][3]int, length * (length - 1) / 2)
        split_linear_work(length)
    }

    sync.barrier_wait(&BARRIER)

    start, end := global_starts_ends[this_idx], global_starts_ends[this_idx+1]
    fill_edges(global_E[:], global_V, start, end)

    sync.barrier_wait(&BARRIER)

    return this_idx == 0 ? kruskal_mst(global_V, global_E) : [2]int{}
}

read_graph_vertices :: proc() -> [][3]int
{
    V := make([dynamic][3]int, 0, INPUT_LEN)
    it := string(INPUT)
    for line in strings.split_lines_iterator(&it)
    {
        line := line
        x, _ := strings.split_iterator(&line, ",")
        y, _ := strings.split_iterator(&line, ",")
        z :=  line
        x_int, _ := strconv.parse_int(x)
        y_int, _ := strconv.parse_int(y)
        z_int, _ := strconv.parse_int(z)
        append(&V, [3]int{ x_int, y_int, z_int })
    }
    return V[:]
}

fill_edges :: proc(E, V: [][3]int, start, end: int)
{
    length := len(V)
    two_len := 2 * length
    idx := (start * (two_len - start - 1)) >> 1
    for i in start..<end do for j in i+1..<length
    {
        distance := euclidean_distance(V[i], V[j])
        E[idx] = [3]int{ distance, i, j }
        idx += 1
    }
}

kruskal_mst :: proc(V: [][3]int, E: [dynamic][3]int) -> [2]int
{
    results: [2]int

    // Heapify edges.
    heap: pq.Priority_Queue([3]int);
    pq.init_from_dynamic_array(&heap, E,
        proc(a, b: [3]int) -> bool { return a[0] < b[0] },
        proc(q: [][3]int, i, j: int) { q[i], q[j] = q[j], q[i] }
    )

    uf := make_union_find(len(V))
    for _ in 0..<1000
    {
        edge := pq.pop(&heap)
        uf_union(&uf, edge[1], edge[2])
    }
    results[0] = mul_3_largest(uf)

    for
    {
        edge := pq.pop(&heap)
        uf_union(&uf, edge[1], edge[2])
        if uf.size == 1
        {
            results[1] = V[edge[1]].x * V[edge[2]].x
            break
        }
    }
    return results
}

euclidean_distance :: proc(a, b: [3]int) -> int
{
    c := a - b
    d := c * c
    result: int
    for n in d do result += n
    return result
}

make_union_find :: proc(size: int) -> uf
{
    uf: uf
    uf.arrs = make([][2]int, size)
    for i in 0..<size do uf.arrs[i] = [2]int{ i, 1 }
    uf.size = size
    return uf
}

uf_find :: proc(uf: ^uf, idx: int) -> int
{
    if uf.arrs[idx][0] != idx do uf.arrs[idx][0] = uf_find(uf, uf.arrs[idx][0])
    return uf.arrs[idx][0]
}

uf_union :: proc(uf: ^uf, p, q: int)
{
    p := uf_find(uf, p)
    q := uf_find(uf, q)
    if p != q
    {
        size := uf.arrs[p][1] + uf.arrs[q][1]
        uf.size -= 1
        if uf.arrs[p][1] < uf.arrs[q][1]
        {
            uf.arrs[q][1] = size
            uf.arrs[p] = [2]int{ q, 0 }
        }
        else
        {
            uf.arrs[p][1] = size
            uf.arrs[q] = [2]int{ p, 0 }
        }
    }
}

mul_3_largest :: proc(uf: uf) -> int
{
    i, j, k: int
    for p in uf.arrs
    {
        size := p[1]
        if size > i do i, j, k = size, i, j
        else if size > j do j, k = size, j
        else if size > k do k = size
    }
    return i * j * k
}
