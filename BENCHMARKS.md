CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 10.0 ns 18.0 ns 17.0 ns 45.0 ns (+-2%) iter=98110     
day 01:  7.9 µs 22.9 µs  7.6 µs 38.5 µs (+-1%) iter=39110    
day 02:  9.9 µs  5.8 µs 18.2 µs 34.0 µs (+-1%) iter=9110    
day 03: 10.0 ns 17.6 µs 15.2 µs 32.9 µs (+-1%) iter=19110    
day 04: 19.0 ns 55.0 µs 27.1 µs 82.2 µs (+-1%) iter=9110    
day 05: 12.6 µs  1.2 µs  2.5 µs 16.4 µs (+-2%) iter=98110    
day 06:  0.1 µs 12.5 µs  0.4 ms  0.4 ms (+-1%) iter=2010    
day 07: 43.9 µs 81.0 µs 77.9 µs  0.2 ms (+-1%) iter=1510    
day 08:  0.8 µs  0.6 µs  1.6 µs  3.2 µs (+-1%) iter=19110    
day 09: 32.1 µs 78.8 µs 84.7 µs  0.1 ms (+-1%) iter=1010    
day 10:  8.2 µs  8.9 µs  7.2 µs 24.4 µs (+-2%) iter=98110     
day 11:  0.2 ms 45.0 µs  0.2 ms  0.5 ms (+-1%) iter=1010    
day 12: 16.0 ns  0.2 ms  0.2 ms  0.5 ms (+-1%) iter=1010    
day 13:  5.8 µs  1.2 µs  1.5 µs  8.6 µs (+-3%) iter=98110     
day 14:  6.5 µs  1.3 µs  0.1 ms  0.1 ms (+-1%) iter=1010    
day 15:  4.4 µs  0.1 ms  0.2 ms  0.4 ms (+-0%) iter=1010    

all days total:         2.7 ms
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 00:  8.0 ns 16.0 ns 16.0 ns 40.0 ns (+-5%) iter=98110     
day 01:  7.3 µs 14.4 µs  6.8 µs 28.5 µs (+-1%) iter=9110    
day 02: 11.0 µs  1.4 µs  4.0 µs 16.5 µs (+-1%) iter=19110    
day 03:  6.0 ns 21.1 µs 18.8 µs 39.9 µs (+-1%) iter=19110    
day 04:  6.0 ns 27.8 µs 10.7 µs 38.5 µs (+-0%) iter=9110    
day 05: 13.3 µs  1.7 µs  2.5 µs 17.5 µs (+-2%) iter=98110    
day 06:  0.1 µs 10.4 µs  0.2 ms  0.2 ms (+-1%) iter=1010    
day 07: 23.4 µs 50.3 µs 37.3 µs  0.1 ms (+-3%) iter=9910    
day 08:  1.2 µs  0.9 µs  2.8 µs  5.0 µs (+-3%) iter=98110    
day 09: 19.1 µs 32.0 µs 75.8 µs  0.1 ms (+-2%) iter=9910    
day 10:  6.2 µs  8.1 µs  7.4 µs 21.8 µs (+-1%) iter=14110    
day 11:  0.1 ms 41.3 µs  0.2 ms  0.4 ms (+-1%) iter=1010    
day 12: 13.0 ns  0.1 ms  0.1 ms  0.3 ms (+-2%) iter=9910    
day 13:  5.9 µs  0.7 µs  0.7 µs  7.4 µs (+-1%) iter=14110    
day 14:  7.5 µs  1.5 µs 79.8 µs 88.9 µs (+-1%) iter=14110    
day 15:  4.9 µs 67.8 µs  0.1 ms  0.2 ms (+-7%) iter=9910     

all days total:         1.8 ms
```
