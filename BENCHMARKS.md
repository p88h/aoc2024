CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
        parse   part1   part2   total
day 01:  7.9 µs 22.4 µs  7.6 µs 38.0 µs (+-1%) iter=24110    
day 02: 10.7 µs  5.9 µs 17.6 µs 34.3 µs (+-1%) iter=9110    
day 03: 11.0 ns 15.4 µs 14.0 µs 29.5 µs (+-1%) iter=19110    
day 04: 12.0 ns 56.1 µs 27.5 µs 83.6 µs (+-1%) iter=14110    
day 05: 12.6 µs  1.3 µs  2.5 µs 16.5 µs (+-4%) iter=98110    
day 06:  0.1 µs 12.4 µs  0.4 ms  0.4 ms (+-3%) iter=9910    
day 07: 43.7 µs 84.7 µs 78.5 µs  0.2 ms (+-1%) iter=2510    
day 08:  1.3 µs  0.6 µs  1.7 µs  3.7 µs (+-1%) iter=9110    
day 09: 29.5 µs 78.0 µs 80.2 µs  0.1 ms (+-1%) iter=1010    
day 10:  8.0 µs  9.1 µs  6.7 µs 23.9 µs (+-1%) iter=24110     
day 11:  0.2 ms 41.4 µs  0.2 ms  0.5 ms (+-1%) iter=2510    
day 12: 20.0 ns  0.2 ms  0.2 ms  0.5 ms (+-1%) iter=1010    
day 13:  6.1 µs  1.2 µs  1.5 µs  8.9 µs (+-5%) iter=98110     
day 14:  5.5 µs  1.3 µs  0.1 ms  0.1 ms (+-1%) iter=1510    
day 15:  3.8 µs  0.1 ms  0.2 ms  0.4 ms (+-1%) iter=1010    
day 16: 74.2 µs  0.1 ms 14.9 µs  0.2 ms (+-1%) iter=1510    
day 17: 47.0 ns  0.3 µs  9.6 µs 10.0 µs (+-1%) iter=9110    
day 18: 22.0 µs 14.7 µs  4.3 µs 41.0 µs (+-1%) iter=19110    
day 19:  6.4 µs  0.1 ms 51.0 ns  0.1 ms (+-2%) iter=9910    
day 20: 19.1 µs  0.2 ms  1.0 ms  1.2 ms (+-1%) iter=160    
day 21: 24.0 ns  1.1 µs  1.0 µs  2.3 µs (+-5%) iter=98110    
day 22:  0.2 ms  0.1 ms  1.4 ms  1.8 ms (+-2%) iter=1000    
day 23: 54.6 µs 21.6 µs  4.9 µs 81.3 µs (+-3%) iter=90010    
day 24: 11.7 µs  2.3 µs  1.3 µs 15.4 µs (+-1%) iter=34110    
day 25: 12.2 µs 21.7 µs 24.0 ns 34.0 µs (+-1%) iter=9110    

all days total:         6.2 ms
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 01:  7.6 µs 14.4 µs  7.4 µs 29.5 µs (+-1%) iter=14110    
day 02: 11.6 µs  1.2 µs  4.7 µs 17.6 µs (+-3%) iter=98110    
day 03:  7.0 ns 22.2 µs 19.8 µs 42.1 µs (+-1%) iter=9110    
day 04:  6.0 ns 28.8 µs 11.5 µs 40.3 µs (+-1%) iter=9110    
day 05: 13.6 µs  1.3 µs  2.5 µs 17.5 µs (+-2%) iter=98110    
day 06:  0.1 µs 10.6 µs  0.2 ms  0.2 ms (+-1%) iter=3010    
day 07: 23.9 µs 45.6 µs 37.3 µs  0.1 ms (+-1%) iter=1510    
day 08:  1.2 µs  1.0 µs  2.8 µs  5.1 µs (+-3%) iter=98110    
day 09: 19.7 µs 34.7 µs 79.7 µs  0.1 ms (+-1%) iter=1010    
day 10:  5.7 µs  8.3 µs  7.5 µs 21.6 µs (+-0%) iter=9110    
day 11:  0.1 ms 40.1 µs  0.2 ms  0.4 ms (+-1%) iter=1010    
day 12: 12.0 ns  0.1 ms  0.1 ms  0.3 ms (+-4%) iter=9910    
day 13:  6.3 µs  0.6 µs  0.7 µs  7.7 µs (+-1%) iter=14110    
day 14:  7.3 µs  1.4 µs 80.9 µs 89.8 µs (+-1%) iter=9110    
day 15:  4.1 µs 60.8 µs  0.1 ms  0.1 ms (+-7%) iter=9910     
day 16: 48.1 µs 80.1 µs 18.8 µs  0.1 ms (+-1%) iter=1510    
day 17: 42.0 ns  0.2 µs  5.3 µs  5.6 µs (+-1%) iter=49110    
day 18: 88.6 µs 14.1 µs  5.4 µs  0.1 ms (+-1%) iter=1010    
day 19:  3.6 µs 66.5 µs 39.0 ns 70.2 µs (+-1%) iter=51010    
day 20: 13.0 µs  0.1 ms  0.5 ms  0.7 ms (+-1%) iter=2010    
day 21: 15.0 ns  1.8 µs  1.5 µs  3.4 µs (+-2%) iter=98110    
day 22:  0.1 ms 95.5 µs  0.6 ms  0.9 ms (+-1%) iter=1110    
day 23: 35.5 µs 24.2 µs  6.0 µs 65.8 µs (+-1%) iter=9110    
day 24:  9.0 µs  2.9 µs  0.8 µs 12.8 µs (+-1%) iter=9110    
day 25: 24.7 µs 29.5 µs 27.0 ns 54.3 µs (+-0%) iter=9110    

all days total:         4.0 ms
```
