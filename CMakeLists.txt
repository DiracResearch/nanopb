cmake_minimum_required(VERSION 3.0)

project(nanopb C)

# Set nanopb generator source dir
set(NANOPB_GENERATOR_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/generator" CACHE INTERNAL "")

include(cmake/nanopb_generate.cmake)

# Find the protoc Executable
find_program(PROTOBUF_PROTOC_EXECUTABLE
    NAMES protoc
    NO_CMAKE_FIND_ROOT_PATH
    DOC "The Google Protocol Buffers Compiler"
)
mark_as_advanced(PROTOBUF_PROTOC_EXECUTABLE)

find_package(PythonInterp REQUIRED)

add_library(nanopb 
    pb.h
    pb_decode.c 
    pb_encode.c 
    pb_common.c 
    pb_decode.h 
    pb_encode.h 
    pb_common.h)

target_include_directories(nanopb PUBLIC ./)

option(NANOPB_FIELD_32BIT "Add support for tag numbers > 65536 and fields larger than 65536 bytes." OFF)
if(NANOPB_FIELD_32BIT)
    target_compile_definitions(nanopb PUBLIC PB_FIELD_32BIT=1)
endif()

option(NANOPB_FIELD_16BIT "Add support for tag numbers > 255 and fields larger than 255 bytes." OFF)
if(NANOPB_FIELD_16BIT)
    target_compile_definitions(nanopb PUBLIC PB_FIELD_16BIT=1)
endif()

option(NANOPB_NO_PACKED_STRUCTS "Define this if your CPU/compiler combination does not support unaligned memory access to packed structures." OFF)
if(NANOPB_NO_PACKED_STRUCTS)
    target_compile_definitions(nanopb PUBLIC PB_NO_PACKED_STRUCTS=1)
endif()

option(NANOPB_ENABLE_MALLOC "Enable support for dynamically allocated fields" OFF)
if(NANOPB_ENABLE_MALLOC)
    target_compile_definitions(nanopb PUBLIC PB_ENABLE_MALLOC=1)
endif()

option(NANOPB_NO_ERRMSG "Disable support for error messages in order to save some code space." OFF)
if(NANOPB_NO_ERRMSG)
    target_compile_definitions(nanopb PUBLIC PB_NO_ERRMSG=1)
endif()



option(NANOPB_BUILD_EXAMPLES "Includes examples in the build" OFF)
if(NANOPB_BUILD_EXAMPLES)
    add_subdirectory(examples/cmake_simple_new)
endif()
