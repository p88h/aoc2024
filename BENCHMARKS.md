CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 10.0 ns 17.0 ns 17.0 ns 44.0 ns (+-1%) iter=29110     
day 01:  8.1 µs 22.1 µs  7.9 µs 38.1 µs (+-2%) iter=98110    
day 02: 10.6 µs  5.9 µs 17.8 µs 34.4 µs (+-1%) iter=9110    
day 03: 10.0 ns 16.3 µs 13.9 µs 30.3 µs (+-1%) iter=19110    
day 04: 12.0 ns 56.2 µs 26.3 µs 82.5 µs (+-1%) iter=9110    
day 05: 12.0 µs  1.1 µs  2.9 µs 16.1 µs (+-2%) iter=98110    
day 06:  0.1 µs 13.1 µs  0.4 ms  0.4 ms (+-1%) iter=3010    
day 07: 45.9 µs 78.1 µs 79.1 µs  0.2 ms (+-0%) iter=1010    
day 08:  1.3 µs  0.6 µs  1.7 µs  3.6 µs (+-2%) iter=98110    
day 09: 27.9 µs 75.6 µs 81.2 µs  0.1 ms (+-1%) iter=9010    
day 10:  8.2 µs  8.6 µs  6.7 µs 23.7 µs (+-1%) iter=24110    
day 11:  0.2 ms 41.5 µs  0.2 ms  0.5 ms (+-1%) iter=2510    
day 12: 20.0 ns  0.2 ms  0.2 ms  0.5 ms (+-1%) iter=9510    
day 13:  6.1 µs  1.1 µs  1.4 µs  8.7 µs (+-5%) iter=98110    
day 14:  7.6 µs  1.7 µs  1.1 ms  1.1 ms (+-1%) iter=510    

all days total:         3.2 ms
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 00:  9.0 ns 14.0 ns 16.0 ns 39.0 ns (+-3%) iter=98110     
day 01:  7.6 µs 14.9 µs  7.5 µs 30.0 µs (+-1%) iter=14110    
day 02: 11.1 µs  1.2 µs  4.9 µs 17.3 µs (+-1%) iter=9110    
day 03:  6.0 ns 22.4 µs 19.7 µs 42.2 µs (+-0%) iter=9110    
day 04:  6.0 ns 28.3 µs 11.3 µs 39.6 µs (+-3%) iter=98110    
day 05: 14.1 µs  1.6 µs  2.6 µs 18.5 µs (+-1%) iter=9110    
day 06:  0.1 µs 11.4 µs  0.2 ms  0.2 ms (+-1%) iter=1010    
day 07: 25.9 µs 44.7 µs 41.7 µs  0.1 ms (+-6%) iter=9910     
day 08:  1.4 µs  1.0 µs  2.7 µs  5.2 µs (+-1%) iter=9110    
day 09: 20.1 µs 37.7 µs 76.0 µs  0.1 ms (+-2%) iter=9910    
day 10:  5.6 µs  8.8 µs  8.1 µs 22.6 µs (+-4%) iter=98110     
day 11:  0.1 ms 39.9 µs  0.2 ms  0.4 ms (+-3%) iter=9910    
day 12: 12.0 ns  0.1 ms  0.1 ms  0.3 ms (+-1%) iter=3010    
day 13:  5.9 µs  0.8 µs  0.7 µs  7.5 µs (+-1%) iter=14110    

all days total:         1.5 ms
```
