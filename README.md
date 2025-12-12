# AoC 2025

For this year's AoC, my challenge is making a single program that solves the entire AoC. The constraints are:

- Problems must be solved sequentially (day X + 1 can only be solved after day X is solved);
- All solutions must be written to the same file;
- The entire code is multi-threaded;
- No memory leaks allowed.

I was inspired by this [article](https://www.rfleury.com/p/multi-core-by-default) to make this multi-threaded in a simple way.

Total runtime picking the faster out of the single-threaded and the multi-threaded implementation each day: sub 24 ms. In order to significantly lower this, I need a better algorithm for day 2 part 2 (currently brute force).

## Commentary by Day

01: This problem is serial, so every line must be processed sequentially. Adapting it to single threaded execution was trivial.

02: Great problem for multithreading. The input has independent tasks, and each task can take a variable amount of work. A way to do load balancing among threads is to have an atomic counter that's incremented to see which task each thread gets. This way, a thread with short tasks can get more tasks than a thread with long tasks. When it comes to parsing the input text, there's a single line. This line could be parsed in parallel, but that's probably negligible.

03: Each thread takes some of the lines to process. All we need to know to do this cleanly is the line length and the number of lines (or file length). I hard coded them, but this could be read dynamically from the input.

### 04: Multithreaded fixed-point algorithm and bit trickery

04: This was a pretty interesting problem to multithread. Each thread gets a range of rows, and they must check the contents of neighboring rows, which might be owned by other threads. Instead of mutating neighbor counts when removing a cell, I chose to recompute neighbor counts in the rows in the boundaries with other threads, evading WAW race conditions. This was made more efficient by having 3 distinct arrays, one for storing cells in the upper border, another for the lower border, and another for cells deep into the thread's range. This approach of having different arrays based on conditionals instead of testing conditions on array members is based on Data-Oriented Design (dodbook). Back to multithreading, when all threads have reached a local fixed-point, they sync, then confirm they really are in a fixed-point, then sync again, then exit if they really were in a global fixed-point, otherwise they sync once more and go back to the loop.

05: Parsing intervals, building a single list, sorting it and merging intervals is best done single threaded. We could have each thread parse a subset of the lines, then merge multiple lists, and sorting in parallel is fine with custom implementations, but that's overkill for 177 lines, not to mention inefficient. However! Once the merged intervals are built, we can check if the ids are in intervals in parallel. Split lines roughly, as they don't have the same length, and go to town. The dataset is too small for this to be worth it, though, and the single threaded implementation is faster.

06: Splitting this problem in chunks requires finding vertical slices of text filled with spaces.

07: This problem is great for multithreading, but it requires a different paradigm. Ideally, there would be a runtime, such as OpenCilk which decides whether to spawn a new thread for a recursive invocation to depth-first-search. The approach of splitting work by ranges or tasks does not work for this kind of recursive approach. As such, I did not implement a multithreaded solution. If this was production code with high CPU usage, I'd use one existing runtime for parallel programming.

### 08 & 09: Load balancing ranges with linear work

08: Kruskal's is a greedy algorithm. Greedy algorithms always depend on the immediately prior iteration, so they must be single threaded. The work that can be done in parallel is generating edges. This requires instantiating a dynamic array (required for priority queue API), but indexing into it with indexes instead of appending (required for lock-free thread safety). This requires some not too obvious math to find the index in which to add the index to the dynamic array. Also, load balancing between threads requires passing non-uniform ranges, since the there linear work based on the index (earlier indexes take more work). Some tricky math involved, although it could be done with binary search as well.

09: Same thing about linear work, so I pulled that logic into `main.odin`. Other than that, parse the input single threaded, then process each point in parallel, then go through all solutions and get the max of them. The main trick here is to store each thread's result in a shared array and then look for the max. Otherwise, this would require locking, reading the current shared result, checking if the local result is greater, storing if it is, and then unlocking.

### 10: Bit tricks in Odin and ILP with scipy

10: Lines are independent, so split lines between threads. Here there's a BFS solution to part 1 in Odin and integer linear programming solutions using scipy to both parts in Python, since there's no ILP Odin library that I'm aware of.

11: Each depth first search is independent, so each is done by a different thread.

12: Each line is independent, so split chunks at line boundaries.
