CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 10.0 ns 17.0 ns 17.0 ns 44.0 ns (+-1%) iter=14110     
day 01: 8.3 µs  22.9 µs 7.8 µss 39.0 µs (+-1%) iter=24110    
day 02: 9.7 µss 5.5 µs  17.8 µs 33.7 µs (+-1%) iter=14110    
day 03: 10.0 ns 17.0 µs 15.1 µs 31.9 µs (+-1%) iter=14110    
day 04: 10.0 ns 56.0 µs 27.1 µs 82.1 µs (+-1%) iter=34110    
day 05: 12.2 µs 1.1 µs  2.4 µs  15.9 µs (+-2%) iter=98110     
day 06: 0.1 µs  12.9 µs 0.3 ms  0.4 ms (+-1%) iter=2510    
day 07: 48.2 µs 82.1 µs 77.1 µs 0.2 ms (+-1%) iter=1510    

all days total:         816.6 µs
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
TBD
```
