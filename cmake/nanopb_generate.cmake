# This is an example script for use with CMake projects for locating and configuring
# the nanopb library.
#
# The following variables can be set and are optional:
#
#   NANOPB_IMPORT_DIRS       - List of additional directories to be searched for
#                              imported .proto files.
#
#   NANOPB_GENERATE_CPP_APPEND_PATH - By default -I will be passed to protoc
#                                     for each directory where a proto file is referenced.
#                                     Set to FALSE if you want to disable this behaviour.
#
# The following cache variables are also available to set or use:
#   PROTOBUF_PROTOC_EXECUTABLE - The protoc compiler
#   NANOPB_GENERATOR_SOURCE_DIR - The nanopb generator source
#
#  ====================================================================
#
# NANOPB_GENERATE (public function)
#   TARGET = The target to which the proto file belongs.
#            This is for example used to get include paths.
#   SRCS   = Variable to define with autogenerated
#            source files
#   HDRS   = Variable to define with autogenerated
#            header files
#   ARGN   = proto files
#
#  ====================================================================

#=============================================================================
# Copyright 2009 Kitware, Inc.
# Copyright 2009-2011 Philip Lowman <philip@yhbt.com>
# Copyright 2008 Esben Mose Hansen, Ange Optimization ApS
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# * Neither the names of Kitware, Inc., the Insight Software Consortium,
#   nor the names of their contributors may be used to endorse or promote
#   products derived from this software without specific prior written
#   permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#=============================================================================
#
# Changes
# 2013.01.31 - Pavlo Ilin - used Modules/FindProtobuf.cmake from cmake 2.8.10 to
#                           write FindNanopb.cmake
#
#=============================================================================

function(nanopb_generate TARGET SRCS HDRS)
  if(NOT ARGN)
    return()
  endif()

  if(NANOPB_GENERATE_CPP_APPEND_PATH)
    # Create an include path for each file specified
    foreach(FIL ${ARGN})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(ABS_PATH ${ABS_FIL} PATH)

      list(FIND _nanobp_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _nanobp_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  else()
    set(_nanobp_include_path -I ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  if(DEFINED NANOPB_IMPORT_DIRS)
    foreach(DIR ${NANOPB_IMPORT_DIRS})
      get_filename_component(ABS_PATH ${DIR} ABSOLUTE)
      list(FIND _nanobp_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _nanobp_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  endif()

  set(${SRCS})
  set(${HDRS})

  set(GENERATOR_PATH ${CMAKE_BINARY_DIR}/nanopb/generator)

  set(NANOPB_GENERATOR_EXECUTABLE ${GENERATOR_PATH}/nanopb_generator.py)

  set(GENERATOR_CORE_DIR ${GENERATOR_PATH}/proto)
  set(GENERATOR_CORE_SRC
      ${GENERATOR_CORE_DIR}/nanopb.proto
      ${GENERATOR_CORE_DIR}/plugin.proto)

  # Treat the source diretory as immutable.
  #
  # Copy the generator directory to the build directory before
  # compiling python and proto files.  Fixes issues when using the
  # same build directory with different python/protobuf versions
  # as the binary build directory is discarded across builds.
  #
  add_custom_command(
      OUTPUT ${NANOPB_GENERATOR_EXECUTABLE} ${GENERATOR_CORE_SRC}
      COMMAND ${CMAKE_COMMAND} -E copy_directory
      ARGS ${NANOPB_GENERATOR_SOURCE_DIR} ${GENERATOR_PATH}
      VERBATIM)

  set(GENERATOR_CORE_PYTHON_SRC)
  foreach(FIL ${GENERATOR_CORE_SRC})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(FIL_WE ${FIL} NAME_WE)

      set(output "${GENERATOR_CORE_DIR}/${FIL_WE}_pb2.py")
      set(GENERATOR_CORE_PYTHON_SRC ${GENERATOR_CORE_PYTHON_SRC} ${output})
      add_custom_command(
        OUTPUT ${output}
        COMMAND ${PROTOBUF_PROTOC_EXECUTABLE}
        ARGS -I${GENERATOR_PATH}/proto
          --python_out=${GENERATOR_CORE_DIR} ${ABS_FIL}
        DEPENDS ${ABS_FIL}
        VERBATIM)
  endforeach()

  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)

    # Get relative path from current source dir, this is used to 
    # place the generated header file in the same directory structure
    # as the proto file.
    file(RELATIVE_PATH FIL_REL_SOURCE ${CMAKE_CURRENT_SOURCE_DIR} ${ABS_FIL})
    get_filename_component(FIL_DIR_REL ${FIL_REL_SOURCE} DIRECTORY)

    # Produced absoulte path without extension
    STRING(REGEX REPLACE "[.]proto" "" ABS_FIL_WO ${ABS_FIL} )
    SET(NANOPB_OPTIONS_FILE ${ABS_FIL_WO}.options)

    set(NANOPB_OPTIONS)
    if(EXISTS ${NANOPB_OPTIONS_FILE})
        set(NANOPB_OPTIONS "-f" ${NANOPB_OPTIONS_FILE})
    else()
        set(NANOPB_OPTIONS_FILE)
    endif()

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.c")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.h")
    
    # Have to jump through some hoops to get the generator expression for INCLUDE_DIRECTORIES to work correctly...
    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb"
             "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.c"
             "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.h"
             "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}_nano_pb_temp_script.cmake"
      # create a temporary script, this is needed to get the spaces between arguments to be 
      # corretly added. Seems obscure but this is the best way I have managed to do it...
      COMMAND ${CMAKE_COMMAND}
      ARGS -E echo "execute_process(COMMAND \${ARG_EXE} \${ARG1} \${ARG2})" > ${FIL_WE}_nano_pb_temp_script.cmake
      # Make sure that output directory exists to avoid warning from protoc
      COMMAND ${CMAKE_COMMAND}
      ARGS -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/${FIL_DIR_REL}"
      # run protoc through the temporary script to get spaces to appear correctly
      COMMAND ${CMAKE_COMMAND}
      ARGS 
         "-DARG1=-I$<JOIN:$<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>,$<SEMICOLON>-I>"
         "-DARG2=-I${GENERATOR_PATH};-I${GENERATOR_CORE_DIR};-I${CMAKE_CURRENT_BINARY_DIR};${_nanobp_include_path};-o${FIL_WE}.pb;${ABS_FIL}"
         "-DARG_EXE=${PROTOBUF_PROTOC_EXECUTABLE}"
         -P ${FIL_WE}_nano_pb_temp_script.cmake
      # Run nanopb generator
      COMMAND ${PYTHON_EXECUTABLE}
      ARGS ${NANOPB_GENERATOR_EXECUTABLE} ${FIL_WE}.pb ${NANOPB_OPTIONS}
      # Copy header to correct folder
      COMMAND ${CMAKE_COMMAND}
      ARGS -E copy "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.h" "${CMAKE_CURRENT_BINARY_DIR}/${FIL_DIR_REL}/${FIL_WE}.pb.h"
      DEPENDS ${ABS_FIL} ${GENERATOR_CORE_PYTHON_SRC} ${NANOPB_OPTIONS_FILE}
      COMMENT "Running C++ protocol buffer compiler on ${FIL} and nanopb generator on ${FIL_WE}.pb"
      VERBATIM )
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} ${NANOPB_SRCS} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} ${NANOPB_HDRS} PARENT_SCOPE)

endfunction()