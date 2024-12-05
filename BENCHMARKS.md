All benchmarks running on 12-core / 24-thread Intel Core I7-13700K

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
