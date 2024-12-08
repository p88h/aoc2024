CPU: Intel Core I7-13700K (8+8-core / 24-thread)

OS: Win11 + WSL2 / Ubuntu 24.04

Zig: `0.14.0-dev.1911+3bf89f55c`

```
$ zig build -Doptimize=ReleaseFast run -- all
        parse   part1   part2   total
day 00: 11.0 ns 17.0 ns 17.0 ns 45.0 ns (+-1%) iter=29110     
day 01: 8.1 µs  22.4 µs 7.7 µss 39.2 µs (+-1%) iter=9110    
day 02: 11.0 µs 5.7 µs  17.3 µs 35.3 µs (+-1%) iter=9110    
day 03: 13.0 ns 18.3 µs 18.5 µs 36.6 µs (+-1%) iter=19110    
day 04: 13.0 ns 53.1 µs 21.4 µs 75.5 µs (+-2%) iter=98110    
day 05: 12.9 µs 1.2 µs  2.9 µs  16.8 µs (+-1%) iter=34110    
day 06: 0.1 µs  13.0 µs 0.3 ms  0.4 ms (+-1%) iter=4010    
day 07: 43.6 µs 81.7 µs 76.8 µs 0.2 ms (+-1%) iter=1010    
day 08: 0.8 µs  0.6 µs  1.6 µs  3.2 µs (+-1%) iter=19110    

all days total:         817.9 µs
```

CPU: Apple M3 Max (12+4 cores)

OS: Sonoma 14.7.1

Zig: `0.13.0`

```
        parse   part1   part2   total
day 00: 9.0 nss 15.0 ns 17.0 ns 41.0 ns (+-10%) iter=98110    
day 01: 7.7 µs  14.5 µs 6.5 µss 29.3 µs (+-1%) iter=14110    
day 02: 10.8 µs 1.3 µs  4.4 µs  17.2 µs (+-1%) iter=14110    
day 03: 6.0 nss 20.9 µs 18.9 µs 40.6 µs (+-1%) iter=89110    
day 04: 9.0 ns  28.1 µs 11.3 µs 39.4 µs (+-1%) iter=14110    
day 05: 14.0 µs 1.6 µs  2.5 µs  18.2 µs (+-1%) iter=19110    
day 06: 0.1 µs  11.7 µs 0.2 ms  0.2 ms (+-1%) iter=1510    
day 07: 22.9 µs 49.7 µs 35.4 µs 0.1 ms (+-3%) iter=9910    
day 08: 1.2 µs  0.9 µs  2.3 µs  4.7 µs (+-3%) iter=98110    

all days total:         552.1 µs
```
