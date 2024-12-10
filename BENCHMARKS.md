CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 11.0 ns 17.0 ns 17.0 ns 45.0 ns (+-2%) iter=98110     
day 01:  8.1 µs 23.1 µs  7.5 µs 38.8 µs (+-1%) iter=34110    
day 02: 11.9 µs  5.5 µs 17.5 µs 35.0 µs (+-1%) iter=9110    
day 03: 12.0 ns 16.8 µs 15.5 µs 32.3 µs (+-1%) iter=9110    
day 04: 12.0 ns 55.3 µs 26.9 µs 82.3 µs (+-1%) iter=14110    
day 05: 11.9 µs  1.2 µs  2.9 µs 16.1 µs (+-2%) iter=98110    
day 06:  0.2 µs 13.1 µs  0.4 ms  0.4 ms (+-1%) iter=4010    
day 07: 48.4 µs 82.9 µs 79.9 µs  0.2 ms (+-1%) iter=2510    
day 08:  0.8 µs  0.6 µs  1.6 µs  3.1 µs (+-1%) iter=24110    
day 09: 25.6 µs 77.1 µs 89.5 µs  0.1 ms (+-1%) iter=3510    
day 10:  7.5 µs  8.8 µs  7.3 µs 23.7 µs (+-1%) iter=39110    

all days total:         1.0 ms
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 00:  9.0 ns 13.0 ns 16.0 ns 38.0 ns (+-8%) iter=98110     
day 01:  7.7 µs 15.6 µs  7.4 µs 30.8 µs (+-1%) iter=59110    
day 02: 12.2 µs  1.4 µs  4.4 µs 18.0 µs (+-1%) iter=89110    
day 03:  7.0 ns 22.7 µs 20.5 µs 43.3 µs (+-1%) iter=14110    
day 04: 13.0 ns 29.4 µs 11.6 µs 41.1 µs (+-0%) iter=9110    
day 05: 13.9 µs  1.9 µs  3.5 µs 19.4 µs (+-1%) iter=39110    
day 06:  0.1 µs 10.9 µs  0.2 ms  0.3 ms (+-1%) iter=1010    
day 07: 24.1 µs 53.8 µs 44.6 µs  0.1 ms (+-4%) iter=9910     
day 08:  1.3 µs  1.0 µs  3.0 µs  5.3 µs (+-3%) iter=98110    
day 09: 19.0 µs 43.4 µs 84.3 µs  0.1 ms (+-1%) iter=1010    
day 10:  6.3 µs  8.9 µs  7.9 µs 23.2 µs (+-3%) iter=98110    

all days total:         760.8 µs
```
