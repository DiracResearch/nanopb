cmake_minimum_required(VERSION 3.0)

project(nanopb_cmake_simple_new C)

nanopb_generate(PROTO_SRCS PROTO_HDRS simple.proto)
include_directories(${CMAKE_CURRENT_BINARY_DIR})
set_source_files_properties(${PROTO_SRCS} ${PROTO_HDRS}
    PROPERTIES GENERATED TRUE)

add_executable(nanopb_cmake_simple_new 
    simple.c 
    simple.proto
   ${PROTO_SRCS} 
   ${PROTO_HDRS}
)

target_link_libraries(nanopb_cmake_simple_new nanopb)
