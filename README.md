CUDA Game of Life
=================

## Automated playing game on GPU

Uses multithreading ability of CUDA cores in order to optimise the computational time
required to calculate each iteration of the positions.

Example usage

On Ubuntu 16.04
From this directory

* cmake . 

* make

* ./cugol -v -i 9000 glider-gun.txt

-v = verbose, show each iteration, also includes a terminal clear to animate

-i = iterations, how many generations you want the game to calculate the algorithms for