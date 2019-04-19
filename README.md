Game of Life
============

#### Brief

The Game of Life is a self-playing computer game.
It consists of a collection of cells which, based on a few mathematical rules, can live, die or multiply. Cells can have two states, alive and dead and there are rules governing how alive cells become dead cells and how dead cells revive.

My program is written originally in C++, however, the GPU multithreading portion has to be written in CUDA which extends C++

#### GPU (CUDA - Nvidia)

Let us visualise a board of N x M dimensions in which the cells exist on, and a set of rules governing the conditions in which cells die and revive. Given the requirements to determine whether a cell in the next iteration of the board is alive, that cells is required to count the number of it's neighbouring cells, including diagonally. We can expect that the most simple iterative method would require 9 * N * M comparisons, also big O(N * M) time. By multi-threading this computation on the GPU using cuda threads, we can drastically reduce the time required to calculate the next iteration. I will explain below.

#### Theory

Suppose we have a grid of 100 by 100, N = 100 and M = 100

We can expect that a single threaded program would be required to do 100 * 100 * 9 = 90,000 comparisons one by one.

By multithreading the cells and the operations on the cells, we can allocate one CUDA(GPU) thread for each cell such that all the work each cell is done concurrently

In this case, the GPU can complete N * M aka 10,000 cells work in the time it takes the non-GPU method to calculate 1 cells work. Reducing the N * M part of 9 * M * N to 9.

Our previous big O(N * M) is reduced to O(1)

This sounds great and it is a massive improvement, but it's important to consider that when massive amounts of computation is done simultaneously to consider potential race conditions and memory leaks that may occur. Eg. One thread's variable is overwritten by another thread causing the results to be not as intended. These factors can be overcome by various methods, an example method would be to tie the variables to the thread id and block id combination, which is unique between threads. 

Usage
=====

Tested on Ubuntu 16.04

From the top directory of this project

Instructions:

* cmake . 

* make

* ./cugol -v -i 9000 glider-gun.txt

Notes:

-v = verbose, show each iteration, also includes a terminal clear to animate

-i = iterations, how many generations you want the game to calculate the algorithms for

#### Usage Explained
The final application takes in 3 parameters which are passed in command line. The flag v indicates that each iteration should be printed, the flag i indicates how many iterations to apply the algorithms for and finally a text file which is a board of "-" and "X" chars, denoting dead and alive cells respectively in the initial state of the board.