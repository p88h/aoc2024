CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total    
day 01:  8.4 µs 16.7 µs  7.6 µs 32.8 µs (+-2%) iter=98110    
day 02: 10.5 µs  6.0 µs 17.8 µs 34.4 µs (+-1%) iter=14110    
day 03: 11.0 ns 15.7 µs 13.9 µs 29.7 µs (+-1%) iter=14110    
day 04: 10.0 ns 54.7 µs 27.7 µs 82.4 µs (+-1%) iter=14110    
day 05: 12.3 µs  1.2 µs  2.5 µs 16.1 µs (+-2%) iter=98110     
day 06:  0.1 µs 12.8 µs  0.4 ms  0.4 ms (+-1%) iter=3010    
day 07: 48.2 µs 81.1 µs 80.1 µs  0.2 ms (+-1%) iter=1510    
day 08:  1.3 µs  0.6 µs  1.6 µs  3.6 µs (+-1%) iter=19110    
day 09: 28.5 µs 79.3 µs 80.1 µs  0.1 ms (+-1%) iter=2510    
day 10:  7.6 µs  9.5 µs  7.0 µs 24.1 µs (+-2%) iter=98110    
day 11:  0.2 ms 43.9 µs  0.2 ms  0.5 ms (+-1%) iter=1010    
day 12: 19.0 ns  0.2 ms  0.2 ms  0.5 ms (+-1%) iter=1010    
day 13:  6.2 µs  1.2 µs  1.5 µs  9.0 µs (+-3%) iter=98110    
day 14:  5.2 µs  1.3 µs  0.1 ms  0.1 ms (+-1%) iter=4010    
day 15:  3.7 µs  0.1 ms  0.2 ms  0.4 ms (+-0%) iter=1010    
day 16: 66.7 µs  0.1 ms 15.4 µs  0.1 ms (+-1%) iter=3010     
day 17: 47.0 ns  0.3 µs  9.6 µs 10.0 µs (+-1%) iter=9110    
day 18: 22.3 µs 14.6 µs  4.2 µs 41.3 µs (+-1%) iter=14110 
day 19:  6.0 µs  0.1 ms 49.0 ns  0.1 ms (+-3%) iter=9910    

all days total:         3.0 ms
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 01:  7.4 µs 14.5 µs  6.9 µs 28.9 µs (+-1%) iter=19110    
day 02: 11.8 µs  1.2 µs  4.3 µs 17.4 µs (+-3%) iter=98110    
day 03:  6.0 ns 21.1 µs 18.7 µs 39.8 µs (+-0%) iter=19110    
day 04:  6.0 ns 28.4 µs 11.1 µs 39.5 µs (+-1%) iter=19110    
day 05: 13.2 µs  1.4 µs  2.6 µs 17.3 µs (+-1%) iter=14110    
day 06:  0.1 µs 10.5 µs  0.2 ms  0.2 ms (+-1%) iter=1010    
day 07: 28.2 µs 44.8 µs 39.4 µs  0.1 ms (+-1%) iter=1010    
day 08:  1.3 µs  1.0 µs  2.7 µs  5.1 µs (+-3%) iter=98110    
day 09: 19.2 µs 34.4 µs 80.5 µs  0.1 ms (+-1%) iter=1010    
day 10:  5.8 µs  8.2 µs  7.7 µs 21.8 µs (+-3%) iter=98110    
day 11:  0.1 ms 38.8 µs  0.2 ms  0.4 ms (+-1%) iter=3010    
day 12: 12.0 ns  0.1 ms  0.1 ms  0.3 ms (+-3%) iter=9910    
day 13:  6.2 µs  0.6 µs  0.7 µs  7.6 µs (+-2%) iter=98110    
day 14:  7.2 µs  1.7 µs 81.0 µs 90.0 µs (+-1%) iter=39110    
day 15:  3.6 µs 59.8 µs  0.1 ms  0.1 ms (+-5%) iter=9910    
day 16: 45.0 µs 76.5 µs 15.5 µs  0.1 ms (+-1%) iter=2010    
day 17: 40.0 ns  0.3 µs  5.5 µs  5.9 µs (+-1%) iter=9110    
day 18: 86.2 µs 13.6 µs  5.6 µs  0.1 ms (+-1%) iter=1010    
day 19:  4.1 µs 66.6 µs 30.0 ns 70.7 µs (+-0%) iter=14110

all days total:         2.1 ms
```
