#设置cmake所需要的最低版本，低于该版本报错
cmake_minimum_required(VERSION 3.10 FATAL_ERROR)
#默认LANGUAGES是C CXX
project(os VERSION 0.0.1 LANGUAGES C CXX)

if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)
    message(STATUS "enable -std=c++11")
endif()

option(sub "enable subdirector" ON)

set(CMAKE_BUILD_TYPE "Debug")
#-gdwarf-2是由于gcc和gdb的版本不同导致的debug信息不能显示,显示指定debug信息的导出格式
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -Wall -g -ggdb -gdwarf-2")
message(STATUS "compile parameter: ${CMAKE_CXX_FLAGS_DEBUG}")

list(APPEND _sources_assembly AsTest.h)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

add_executable(os_test main.cc ${_sources_assembly})