cmake_minimum_required(VERSION 3.18)
project(ultrasound_fsk VERSION 2.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS_RELEASE "-O3")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_FORTIFY_SOURCE=2 -fstack-protector-strong")

add_library(ultrasound_fsk SHARED
        ${CMAKE_SOURCE_DIR}/../../../../../native/ultrasound_fsk/ultrasound_fsk.cpp
        )

target_include_directories(ultrasound_fsk PUBLIC
        ${CMAKE_SOURCE_DIR}/../../../../../native/ultrasound_fsk
        )

find_library(math_lib m)
target_link_libraries(ultrasound_fsk ${math_lib})