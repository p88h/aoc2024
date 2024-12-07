CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 9.0 ns  12.0 ns 12.0 ns 33.0 ns
day 01: 8.1 µs  17.5 µs 7.5 µs  33.2 µs
day 02: 10.2 µs 5.6 µs  17.8 µs 33.7 µs
day 03: 9.0 ns  16.0 µs 13.6 µs 29.7 µs
day 04: 7.0 ns  53.8 µs 25.6 µs 79.4 µs
day 05: 12.0 µs 1.1 µs  2.5 µs  15.8 µs

all days total:         192.1 µs
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 00: 6.0 ns  11.0 ns 14.0 ns 33.0 ns
day 01: 7.6 µs  13.8 µs 6.6 µs  28.1 µs
day 02: 11.3 µs 1.3 µs  4.7 µs  17.4 µs
day 03: 6.0 ns  20.6 µs 18.2 µs 38.8 µs
day 04: 8.0 ns  28.5 µs 10.5 µs 39.0 µs
day 05: 13.4 µs 1.8 µs  2.9 µs  18.2 µs
day 06: 0.1 µs  10.5 µs 10.5 µs 21.1 µs
day 07: 24.2 µs 0.1 ms  0.1 ms  0.3 ms

all days total:         497.3 µs
```
