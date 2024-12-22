CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 01:  8.0 µs 22.6 µs  7.6 µs 38.3 µs (+-1%) iter=19110    
day 02: 11.0 µs  5.7 µs 18.1 µs 34.9 µs (+-0%) iter=9110    
day 03: 11.0 ns 19.2 µs 16.9 µs 36.2 µs (+-1%) iter=9110    
day 04: 11.0 ns 53.9 µs 22.2 µs 76.1 µs (+-1%) iter=24110    
day 05: 13.4 µs  1.2 µs  2.5 µs 17.2 µs (+-2%) iter=98110    
day 06:  0.1 µs 12.8 µs  0.4 ms  0.4 ms (+-1%) iter=3010    
day 07: 54.6 µs 81.6 µs 80.5 µs  0.2 ms (+-1%) iter=2510    
day 08:  0.8 µs  0.7 µs  1.6 µs  3.3 µs (+-1%) iter=34110    
day 09: 30.8 µs 76.0 µs 88.8 µs  0.1 ms (+-1%) iter=1010    
day 10:  7.8 µs  9.3 µs  7.3 µs 24.5 µs (+-1%) iter=34110    
day 11:  0.2 ms 44.9 µs  0.2 ms  0.5 ms (+-1%) iter=2510     
day 12: 19.0 ns  0.2 ms  0.2 ms  0.5 ms (+-1%) iter=1510    
day 13:  5.7 µs  1.5 µs  1.5 µs  8.9 µs (+-4%) iter=98110    
day 14:  6.2 µs  1.2 µs  0.1 ms  0.1 ms (+-1%) iter=1010    
day 15:  3.3 µs  0.1 ms  0.2 ms  0.3 ms (+-1%) iter=2510    
day 16: 71.8 µs  0.1 ms 15.8 µs  0.2 ms (+-1%) iter=1510     
day 17: 55.0 ns  0.3 µs  9.5 µs  9.9 µs (+-1%) iter=9110    
day 18: 22.4 µs 14.4 µs  4.7 µs 41.5 µs (+-1%) iter=14110    
day 19:  6.0 µs  0.1 ms 44.0 ns  0.1 ms (+-1%) iter=2010    
day 20: 21.3 µs  0.1 ms  0.9 ms  1.1 ms (+-5%) iter=1000    
day 21:  0.4 µs  1.1 µs  1.0 µs  2.6 µs (+-5%) iter=98110    
day 22:  0.3 ms  0.1 ms  1.7 ms  2.2 ms (+-2%) iter=1000    

all days total:         6.4 ms
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 01:  7.3 µs 14.5 µs  7.1 µs 29.0 µs (+-1%) iter=19110     
day 02: 11.6 µs  1.2 µs  4.1 µs 17.0 µs (+-1%) iter=34110    
day 03:  7.0 ns 21.4 µs 19.1 µs 40.5 µs (+-1%) iter=19110    
day 04:  6.0 ns 27.9 µs 10.8 µs 38.8 µs (+-0%) iter=9110    
day 05: 12.7 µs  1.4 µs  2.6 µs 16.8 µs (+-1%) iter=14110    
day 06:  0.1 µs  9.7 µs  0.2 ms  0.3 ms (+-1%) iter=5510     
day 07: 25.7 µs 45.7 µs 41.6 µs  0.1 ms (+-5%) iter=9910    
day 08:  1.2 µs  1.0 µs  2.7 µs  5.0 µs (+-4%) iter=98110    
day 09: 18.6 µs 37.9 µs 73.4 µs  0.1 ms (+-1%) iter=5010    
day 10:  5.8 µs  8.2 µs  7.5 µs 21.6 µs (+-2%) iter=98110    
day 11:  0.1 ms 37.4 µs  0.2 ms  0.4 ms (+-1%) iter=7010    
day 12: 12.0 ns  0.1 ms  0.1 ms  0.3 ms (+-1%) iter=1510    
day 13:  5.9 µs  0.6 µs  0.6 µs  7.3 µs (+-0%) iter=14110    
day 14:  7.0 µs  1.4 µs 80.6 µs 89.2 µs (+-0%) iter=9110    
day 15:  3.2 µs 57.6 µs  0.1 ms  0.1 ms (+-7%) iter=9910     
day 16: 44.5 µs 72.7 µs 15.8 µs  0.1 ms (+-1%) iter=1010    
day 17: 42.0 ns  0.2 µs  5.2 µs  5.5 µs (+-3%) iter=98110    
day 18: 86.3 µs 13.3 µs  5.4 µs  0.1 ms (+-1%) iter=1010    
day 19:  3.8 µs 66.2 µs 62.0 ns 70.1 µs (+-1%) iter=51010    
day 20: 15.7 µs  0.1 ms  0.7 ms  1.0 ms (+-0%) iter=110    
day 21: 15.0 ns  1.8 µs  1.7 µs  3.5 µs (+-1%) iter=29110    
day 22:  0.2 ms  0.1 ms  0.9 ms  1.2 ms (+-1%) iter=260    

all days total:         4.2 ms
```
