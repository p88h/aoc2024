p88h x Advent of Code 2024 (Hello, Zig)
=======================================

This is a repository containing solutions for the 2024 Advent of Code (https://adventofcode.com/).

This years language of choice is Zig. Only Zig. 

With some C dependencies, I guess, but that's the point of Zig, right?

Hopefully, you should be able to run the solutions code by using

```
# run last day
$ zig build run
# run all days
$ zig build -Doptimize=ReleaseFast run -- all
```

But this is Zig. YMMV. 

Benchmarking
============

TBD

Visualisations
==============

There will be some visualisations implemented with Raylib. To get this to run you can try:

```
# this is only needed once, really
$ git submodule init 
# you can also add `-- rec` to have it create a video file. 
$ zig build -Doptimize=ReleaseSafe vis 
```

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

2024 playlist pending. 

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
