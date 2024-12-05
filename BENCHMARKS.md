All benchmarks running on 12-core / 24-thread Intel Core I7-13700K

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 8.0 ns  12.0 ns 12.0 ns 33.0 ns
day 01: 8.1 µs  17.0 µs 7.2 µs  32.5 µs
day 02: 10.6 µs 5.6 µs  17.5 µs 33.8 µs
day 03: 8.0 ns  15.0 µs 12.9 µs 28.0 µs
day 04: 9.0 ns  53.3 µs 25.8 µs 79.1 µs
day 05: 22.5 µs 21.5 µs 41.1 µs 85.2 µs

all days total:         258.8 µs
```
