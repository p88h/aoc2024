CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 10.0 ns 17.0 ns 17.0 ns 44.0 ns (+-1%) iter=34110     
day 01: 8.2 µs  23.3 µs 7.7 µss 39.7 µs (+-2%) iter=98110    
day 02: 10.7 µs 6.2 µs  18.2 µs 34.8 µs (+-1%) iter=19110    
day 03: 10.0 ns 19.3 µs 17.0 µs 35.9 µs (+-0%) iter=9110    
day 04: 12.0 ns 54.1 µs 20.6 µs 76.7 µs (+-0%) iter=9110    
day 05: 13.0 µs 1.2 µs  2.4 µs  17.2 µs (+-1%) iter=34110     
day 06: 0.1 µs  12.7 µs 0.7 ms  0.7 ms (+-1%) iter=610    
day 07: 47.6 µs 77.1 µs 77.6 µs 0.2 ms (+-1%) iter=3010    

all days total:         1.1 ms
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
TBD
```
