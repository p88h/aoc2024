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
