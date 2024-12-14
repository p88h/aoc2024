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
day 00:  7.0 ns 14.0 ns 16.0 ns 37.0 ns (+-6%) iter=98110     
day 01:  7.2 µs 14.2 µs  7.2 µs 28.7 µs (+-3%) iter=98110    
day 02: 11.0 µs  1.1 µs  4.3 µs 16.5 µs (+-0%) iter=9110    
day 03:  7.0 ns 21.1 µs 18.7 µs 39.8 µs (+-0%) iter=14110    
day 04: 14.0 ns 28.3 µs 10.6 µs 39.0 µs (+-1%) iter=14110    
day 05: 13.4 µs  1.6 µs  2.5 µs 17.6 µs (+-1%) iter=14110    
day 06:  0.1 µs 10.5 µs  0.2 ms  0.3 ms (+-1%) iter=1010    
day 07: 25.6 µs 51.8 µs 45.1 µs  0.1 ms (+-9%) iter=9910     
day 08:  1.4 µs  1.0 µs  2.8 µs  5.4 µs (+-7%) iter=98110    
day 09: 18.1 µs 32.9 µs 75.4 µs  0.1 ms (+-3%) iter=9910    
day 10:  5.6 µs  8.0 µs  7.5 µs 21.3 µs (+-3%) iter=98110    
day 11:  0.1 ms 37.9 µs  0.2 ms  0.4 ms (+-1%) iter=1010    
day 12: 12.0 ns  0.1 ms  0.1 ms  0.3 ms (+-7%) iter=9910     
day 13:  6.3 µs  0.6 µs  0.6 µs  7.6 µs (+-1%) iter=9110    
day 14:  8.7 µs  1.7 µs  0.7 ms  0.7 ms (+-1%) iter=1010    

all days total:         2.2 ms
```
