# Prefer g++/gcc on Unix when the user has not already selected a compiler.
# Include this file BEFORE the first project() call.
#
# Same role as PreferUnixGcc.cmake in weiwan-gmail/protosim-apb.

if(UNIX)
  if(NOT CMAKE_CXX_COMPILER AND NOT DEFINED ENV{CXX})
    find_program(_RTL_LAB_GXX NAMES g++ g++-14 g++-13 g++-12)
    if(_RTL_LAB_GXX)
      set(CMAKE_CXX_COMPILER "${_RTL_LAB_GXX}")
      message(STATUS "PreferUnixGcc: CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}")
    endif()
  endif()
  if(NOT CMAKE_C_COMPILER AND NOT DEFINED ENV{CC})
    find_program(_RTL_LAB_GCC NAMES gcc gcc-14 gcc-13 gcc-12)
    if(_RTL_LAB_GCC)
      set(CMAKE_C_COMPILER "${_RTL_LAB_GCC}")
      message(STATUS "PreferUnixGcc: CMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
    endif()
  endif()
endif()
