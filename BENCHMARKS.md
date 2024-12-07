CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 16.0 ns 19.0 ns 18.0 ns 54.0 ns
day 01: 8.2 µs  21.9 µs 7.2 µs  37.5 µs
day 02: 11.6 µs 5.6 µs  17.4 µs 34.7 µs
day 03: 18.0 ns 19.1 µs 16.2 µs 35.3 µs
day 04: 17.0 ns 53.3 µs 18.7 µs 72.1 µs
day 05: 13.2 µs 1.5 µs  2.5 µs  17.3 µs
day 06: 91.0 ns 10.6 µs 10.9 µs 21.7 µs
day 07: 45.9 µs 75.3 µs 75.9 µs 0.1 ms

all days total:         416.0 µs
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 00: 7.0 ns  14.0 ns 16.0 ns 39.0 ns
day 01: 7.9 µs  15.1 µs 6.8 µs  29.9 µs
day 02: 11.5 µs 1.3 µs  4.6 µs  17.4 µs
day 03: 8.0 ns  22.8 µs 19.7 µs 42.6 µs
day 04: 7.0 ns  28.7 µs 11.7 µs 40.4 µs
day 05: 14.0 µs 1.8 µs  2.9 µs  18.7 µs
day 06: 0.1 µs  10.6 µs 10.4 µs 21.1 µs
day 07: 24.5 µs 59.0 µs 44.8 µs 0.1 ms

all days total:         299.0 µs
```
