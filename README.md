# AoC 2025

For this year's AoC, my challenge is making a single program that solves the entire AoC. The constraints are:

- Problems must be solved sequentially (day X + 1 can only be solved after day X is solved);
- All solutions must be written to the same file;
- The entire code is multi-threaded;
- No memory leaks allowed.

I was inspired by this [article](https://www.rfleury.com/p/multi-core-by-default) to make this multi-threaded in a simple way.

## Commentary by Day

01: This problem is serial, so every line must be processed sequentially. Adapting it to single threaded execution was trivial.

02: Great problem for multithreading. The input has independent tasks, and each task can take a variable amount of work. A way to do load balancing among threads is to have an atomic counter that's incremented to see which task each thread gets. This way, a thread with short tasks can get more tasks than a thread with long tasks. When it comes to parsing the input text, there's a single line. This line could be parsed in parallel, but that's probably negligible.

03: Each thread takes some of the lines to process. All we need to know to do this cleanly is the line length and the number of lines (or file length). I hard coded them, but this could be read dynamically from the input.

### 04: Multithreaded fixed-point algorithm

This was a pretty interesting problem to multithread. Each thread gets a range of rows, and they must check the contents of neighboring rows, which might be owned by other threads. Instead of mutating neighbor counts when removing a cell, I chose to recompute neighbor counts in the rows in the boundaries with other threads, evading WAW race conditions. This was made more efficient by having 3 distinct arrays, one for storing cells in the upper border, another for the lower border, and another for cells deep into the thread's range. This approach of having different arrays based on conditionals instead of testing conditions on array members is based on Data-Oriented Design (dodbook). Back to multithreading, when all threads have reached a local fixed-point, they sync, then confirm they really are in a fixed-point, then sync again, then exit if they really were in a global fixed-point, otherwise they sync once more and go back to the loop.

05: Parsing intervals, building a single list, sorting it and merging intervals is best done single threaded. We could have each thread parse a subset of the lines, then merge multiple lists, and sorting in parallel is fine with custom implementations, but that's overkill for 177 lines, not to mention inefficient. However! Once the merged intervals are built, we can check if the ids are in intervals in parallel. Split lines roughly, as they don't have the same length, and go to town. The dataset is too small for this to be worth it, though, and the single threaded implementation is faster.

06: Splitting this problem in chunks requires finding vertical slices of text filled with spaces.
