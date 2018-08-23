cmake_minimum_required(VERSION 3.8)
find_package(CUDA QUIET REQUIRED)
cuda_add_executable(cugol cugol.cu)
