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
day 00: 7.0 ns  11.0 ns 14.0 ns 33.0 ns
day 01: 7.6 µs  13.7 µs 6.4 µs  27.7 µs
day 02: 11.5 µs 1.3 µs  4.6 µs  17.5 µs
day 03: 8.0 ns  20.5 µs 18.8 µs 39.3 µs
day 04: 5.0 ns  29.2 µs 10.3 µs 39.6 µs
day 05: 12.9 µs 2.0 µs  2.9 µs  17.9 µs

all days total:         142.2 µs
```
