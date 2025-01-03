p88h x Advent of Code 2024 (Hello, Zig)
=======================================

This is a repository containing solutions for the 2024 Advent of Code (https://adventofcode.com/).

This years language of choice is Zig. Only Zig. 

With some C dependencies, I guess, but that's the point of Zig, right?

First off, to run the full code here, you need to do this:
```
# Do these first, once is enough:
$ git submodule init
$ git submodule update
```

These pull in raylib code, which is only used for visualisations, but necessary for build system not to freak out due to missing dependencies.

Then, you should be able to run the solutions code by using
```
# And then these will work : 
# run last day
$ zig build run
# run one specific day 
$ zig build run -- 4
# run all days
$ zig build -Doptimize=ReleaseFast run -- all

# or alternatively you can try this: it does not even require raylib submodule.
$ zig run src/day04.zig
```

But this is Zig. YMMV. 

Benchmarking
============

Automatic, as long as you use `zig build run`. The runner always benchmarks the results. 
To just run one day once without benchmarks, use `zig run` as above.

Visualisations
==============

`vis` directory contains visualisations for all days implemented with Raylib. To get this to run you can try:

```
$ zig build -Doptimize=ReleaseSafe vis 
# run & record select a specific day 
$ zig build -Doptimize=ReleaseSafe vis -- 23 rec
```

You can also add `-- rec` to have it create a video file. 

And similarly to the regular code runner, you can pass day number after `--` to run that day specifically.
Note that zig run will not work for visualisations due to raylib dependency.

Again, YMMV. Right now it doesn't do much, but seems to work. 

NOTE: You will also most likely need to install a bunch of C dependencies to compile raylib, 
unless you happen to have these installed before. This works with Ubuntu 24.04 LTS, but may not be complete.
```
$ sudo apt-get install xorg-dev libxkbcommon-dev libwayland-dev libglfw3-dev libgles2-mesa-dev
```

Extra note: To get Mesa GL to work *properly* on WSL2, you need to update that, as well, apparently 24.04 LTS is not enough. 
24.10 may work, or simply switch to a fresh(-er) MESA PPA:
```
$ sudo add-apt-repository ppa:kisak/kisak-mesa
$ sudo apt update
$ sudo apt upgrade
```

If all fails, or you don't care about tinkering with build system enough, visualisations are also published to [YouTube](https://www.youtube.com/@p88h.)

You can also hop on straight to the [2024 playlist](https://www.youtube.com/playlist?list=PLgRrl8I0Q168GBdeJp_GqNYsWgRCmVgu5)

Copyright disclaimer
====================

Licensed under the Apache License, Version 2.0 (the "License");
you may not use these files except in compliance with the License.
You may obtain a copy of the License at

   https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
