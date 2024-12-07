CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 10.0 ns 17.0 ns 17.0 ns 44.0 ns (+-2%) iter=98110    
day 01: 8.3 µs  23.8 µs 8.1 µss 40.1 µs (+-1%) iter=9110    
day 02: 10.9 µs 5.6 µs  17.6 µs 34.9 µs (+-1%) iter=9110    
day 03: 10.0 ns 18.8 µs 17.2 µs 35.7 µs (+-1%) iter=9110    
day 04: 12.0 ns 55.0 µs 21.2 µs 76.2 µs (+-1%) iter=59110    
day 05: 13.8 µs 1.1 µs  2.5 µs  17.4 µs (+-3%) iter=98110    
day 06: 0.1 µs  16.7 µs 1.4 ms  1.4 ms (+-1%) iter=160    
day 07: 50.1 µs 79.3 µs 81.1 µs 0.2 ms (+-1%) iter=2010    

all days total:         1.8 ms
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
TBD
```
