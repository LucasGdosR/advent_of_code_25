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
