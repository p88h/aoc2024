All benchmarks running on 12-core / 24-thread Intel Core I7-13700K

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2
day 01: 8.2 µs  16.9 µs 5.7 µs
day 02: 12.4 µs 5.7 µs  17.5 µs
day 03: 15.0 ns 14.6 µs 12.9 µs
day 04: 9.0 ns  54.5 µs 20.4 µs
day 05: 17.8 µs 24.7 µs 42.2 µs
```
