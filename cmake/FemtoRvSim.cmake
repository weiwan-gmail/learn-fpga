# FemtoRV teaching-SoC Verilator hello (step20.v + sim_main.cpp).
# Used by both cmake-system/ and cmake-conan/. Does not replace
# FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV Make / run_verilator.sh.
#
# Firmware hex:
#   UNIX (default): existing GNU Make `helloC.hex` (Linux-proven).
#   Windows / FEMTORV_HEX_VIA_CMAKE: CMake-native RISC-V GCC + host
#   firmware_words (no GNU make). If RISC-V GCC is missing, copy the
#   committed cmake/firmware.helloC.hex fallback.

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/FindVerilatorKit.cmake")

set(FEMTORV_DIR "${RTL_LAB_REPO_ROOT}/FemtoRV")
set(FEMTORV_TUTORIAL_DIR
  "${FEMTORV_DIR}/TUTORIALS/FROM_BLINKER_TO_RISCV")
set(FEMTORV_LIBFEMTORV32 "${FEMTORV_DIR}/FIRMWARE/LIBFEMTORV32")
set(FEMTORV_GOLDEN_HEX "${RTL_LAB_CMAKE_DIR}/firmware.helloC.hex")

option(FEMTORV_HEX_VIA_CMAKE
  "Build helloC.hex with CMake (no GNU make). Implied on Windows."
  OFF)

# Host-only MSVC flags for TB / firmware_words. Verilator may still inject
# GCC flags; rtl_lab_strip_msvc_gcc_flags() runs after verilate().
function(femtorv_msvc_host_target tgt)
  if(NOT MSVC)
    return()
  endif()
  target_compile_definitions(${tgt} PRIVATE
    _CRT_SECURE_NO_WARNINGS
    NOMINMAX
    WIN32_LEAN_AND_MEAN)
  target_compile_options(${tgt} PRIVATE /bigobj /wd4244 /wd4267 /wd4996)
endfunction()

# MSYS2 GNU make is typically not on PATH under a Visual Studio generator.
# Discover it; the Verilator cmake sim path does not require it on Windows.
function(femtorv_find_gnu_make)
  unset(FEMTORV_MAKE CACHE)
  set(_hints "")
  if(RTL_LAB_VERILATOR_BIN)
    get_filename_component(_vbin "${RTL_LAB_VERILATOR_BIN}" DIRECTORY)
    get_filename_component(_vpre "${_vbin}" DIRECTORY)
    get_filename_component(_vmsys "${_vpre}" DIRECTORY)
    list(APPEND _hints "${_vbin}")
    # Only walk to usr/bin when the PE lives under an MSYS2 prefix
    # (e.g. C:/msys64/mingw64/bin). On Unix /bin/verilator_bin this would
    # otherwise become //usr/bin.
    if(_vmsys MATCHES "[Mm][Ss][Yy][Ss]")
      list(APPEND _hints
        "${_vmsys}/usr/bin"
        "${_vmsys}/bin")
    endif()
  endif()
  foreach(_root IN ITEMS
      "C:/msys64" "D:/msys64" "C:/msys32"
      "$ENV{MSYS2_ROOT}" "$ENV{MSYS2_HOME}")
    if(_root)
      list(APPEND _hints
        "${_root}/usr/bin"
        "${_root}/bin"
        "${_root}/mingw64/bin"
        "${_root}/ucrt64/bin"
        "${_root}/clang64/bin")
    endif()
  endforeach()
  find_program(FEMTORV_MAKE
    NAMES make gmake mingw32-make
    HINTS ${_hints})
  if(FEMTORV_MAKE)
    message(STATUS "FemtoRvSim: MAKE=${FEMTORV_MAKE}")
  else()
    message(STATUS
      "FemtoRvSim: GNU make not on PATH (checked MSYS2 usr/bin). "
      "Not required for the Windows Verilator/cmake sim path.")
  endif()
endfunction()

function(femtorv_find_riscv_gcc)
  unset(FEMTORV_RVGCC CACHE)
  set(_hints
    "$ENV{RISCV}/bin"
    "$ENV{RISCV_PREFIX}/bin"
    "C:/msys64/mingw64/bin"
    "C:/msys64/ucrt64/bin"
    "C:/msys64/clang64/bin"
    "D:/msys64/mingw64/bin")
  if(RTL_LAB_VERILATOR_BIN)
    get_filename_component(_vbin "${RTL_LAB_VERILATOR_BIN}" DIRECTORY)
    list(APPEND _hints "${_vbin}")
  endif()
  find_program(FEMTORV_RVGCC
    NAMES
      riscv64-unknown-elf-gcc
      riscv-none-elf-gcc
      riscv-none-embed-gcc
    HINTS ${_hints})
  if(NOT FEMTORV_RVGCC AND CMAKE_HOST_WIN32)
    set(_xpack_globs
      "$ENV{USERPROFILE}/AppData/Roaming/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf-gcc.exe"
      "$ENV{USERPROFILE}/AppData/Roaming/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/bin/riscv-none-elf-gcc.exe"
      "$ENV{LOCALAPPDATA}/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/.content/bin/riscv-none-elf-gcc.exe"
      "$ENV{LOCALAPPDATA}/xPacks/@xpack-dev-tools/riscv-none-elf-gcc/*/bin/riscv-none-elf-gcc.exe")
    file(GLOB _xpack_hits ${_xpack_globs})
    if(_xpack_hits)
      list(GET _xpack_hits 0 FEMTORV_RVGCC)
      set(FEMTORV_RVGCC "${FEMTORV_RVGCC}" CACHE FILEPATH "FEMTORV_RVGCC" FORCE)
    endif()
  endif()
  if(FEMTORV_RVGCC)
    message(STATUS "FemtoRvSim: RISC-V GCC=${FEMTORV_RVGCC}")
  endif()
endfunction()

function(femtorv_add_hex_via_make hex_out)
  if(NOT FEMTORV_MAKE)
    message(FATAL_ERROR
      "FemtoRvSim: GNU make is required on UNIX (helloC.hex).\n"
      "Install make, or configure with -DFEMTORV_HEX_VIA_CMAKE=ON.")
  endif()
  if(NOT FEMTORV_RVGCC)
    message(FATAL_ERROR
      "riscv64-unknown-elf-gcc not found.\n"
      "Install gcc-riscv64-unknown-elf (Linux) or put a RISC-V GCC on PATH.\n"
      "UNIX cmake still calls the existing FemtoRV Make path for firmware.hex.")
  endif()
  add_custom_command(
    OUTPUT "${hex_out}"
    COMMAND "${FEMTORV_MAKE}" -C "${FEMTORV_TUTORIAL_DIR}" helloC.hex
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${FEMTORV_TUTORIAL_DIR}/firmware.hex"
            "${hex_out}"
    DEPENDS
      "${FEMTORV_TUTORIAL_DIR}/FIRMWARE/helloC.c"
      "${FEMTORV_TUTORIAL_DIR}/FIRMWARE/start.S"
      "${FEMTORV_TUTORIAL_DIR}/FIRMWARE/Makefile"
      "${FEMTORV_TUTORIAL_DIR}/Makefile"
    COMMENT "FemtoRV helloC.hex via existing Make (unchanged)"
    VERBATIM)
endfunction()

function(femtorv_add_hex_via_cmake hex_out)
  set(_fw "${FEMTORV_TUTORIAL_DIR}/FIRMWARE")
  set(_words_cpp
    "${FEMTORV_DIR}/FIRMWARE/TOOLS/FIRMWARE_WORDS_SRC/firmware_words.cpp")
  set(_elf_c "${FEMTORV_LIBFEMTORV32}/femto_elf.c")
  add_executable(firmware_words "${_words_cpp}" "${_elf_c}")
  target_include_directories(firmware_words PRIVATE "${FEMTORV_LIBFEMTORV32}")
  target_compile_definitions(firmware_words PRIVATE STANDALONE_FEMTOELF)
  target_compile_features(firmware_words PRIVATE cxx_std_17)
  femtorv_msvc_host_target(firmware_words)

  add_custom_command(
    OUTPUT "${hex_out}"
    COMMAND "${CMAKE_COMMAND}"
      "-DRVGCC=${FEMTORV_RVGCC}"
      "-DWORDS_EXE=$<TARGET_FILE:firmware_words>"
      "-DFW_DIR=${_fw}"
      "-DHEX_OUT=${hex_out}"
      "-DWORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/fw"
      -P "${RTL_LAB_CMAKE_DIR}/BuildFemtoHelloHex.cmake"
    DEPENDS
      firmware_words
      "${_fw}/helloC.c"
      "${_fw}/start.S"
      "${_fw}/bram.ld"
      "${_fw}/io.h"
      "${_words_cpp}"
      "${_elf_c}"
    COMMENT "FemtoRV helloC.hex via CMake (no GNU make)"
    VERBATIM)
endfunction()

function(femtorv_add_hex_via_golden hex_out)
  if(NOT EXISTS "${FEMTORV_GOLDEN_HEX}")
    message(FATAL_ERROR
      "FemtoRvSim: RISC-V GCC not found and golden hex missing:\n"
      "  ${FEMTORV_GOLDEN_HEX}\n"
      "Install xpack riscv-none-elf-gcc (or gcc-riscv64-unknown-elf) and put it on PATH,\n"
      "or pass -DFEMTORV_FIRMWARE_HEX=/path/to/firmware.hex.")
  endif()
  message(WARNING
    "FemtoRvSim: RISC-V GCC not found; using committed golden hex\n"
    "  ${FEMTORV_GOLDEN_HEX}\n"
    "Rebuilds from helloC.c when a RISC-V GCC is on PATH / xpack / MSYS2.")
  add_custom_command(
    OUTPUT "${hex_out}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${FEMTORV_GOLDEN_HEX}" "${hex_out}"
    DEPENDS "${FEMTORV_GOLDEN_HEX}"
    COMMENT "FemtoRV helloC.hex from golden fallback (no RISC-V GCC)"
    VERBATIM)
endfunction()

function(femtorv_sim_setup)
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  endif()
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  rtl_lab_find_verilator()
  include(CheckCXXCompilerFlag)

  femtorv_find_gnu_make()
  femtorv_find_riscv_gcc()

  set(_tb "${FEMTORV_TUTORIAL_DIR}/sim_main.cpp")
  set(_elf_c "${FEMTORV_LIBFEMTORV32}/femto_elf.c")
  set(_rtl "${FEMTORV_TUTORIAL_DIR}/step20.v")
  foreach(_need IN ITEMS _tb _elf_c _rtl)
    if(NOT EXISTS "${${_need}}")
      message(FATAL_ERROR "FemtoRvSim: missing ${${_need}}")
    endif()
  endforeach()

  add_executable(sim_hello
    "${_tb}"
    "${_elf_c}"
    "${RTL_LAB_CMAKE_DIR}/sc_time_stamp.cpp")
  target_include_directories(sim_hello PRIVATE "${FEMTORV_LIBFEMTORV32}")
  target_compile_definitions(sim_hello PRIVATE STANDALONE_FEMTOELF)
  target_compile_features(sim_hello PRIVATE cxx_std_17)
  femtorv_msvc_host_target(sim_hello)

  # Match FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/run_verilator.sh.
  # --relative-includes keeps clockworks.v → ../../RTL/PLL/femtopll.v
  # working when Verilator's cwd is the CMake build dir.
  verilate(sim_hello
    PREFIX VSOC
    TOP_MODULE SOC
    SOURCES "${_rtl}"
    INCLUDE_DIRS
      "${FEMTORV_TUTORIAL_DIR}"
      "${FEMTORV_DIR}/RTL/PLL"
    VERILATOR_ARGS
      --relative-includes
      -DBENCH
      -DBOARD_FREQ=10
      -DCPU_FREQ=10
      -DPASSTHROUGH_PLL
      -Wno-fatal
      -Wno-WIDTHTRUNC
  )
  rtl_lab_strip_msvc_gcc_flags(sim_hello)

  set(_hex_out "${CMAKE_CURRENT_BINARY_DIR}/firmware.hex")
  set(FEMTORV_FIRMWARE_HEX "" CACHE FILEPATH
    "Optional prebuilt firmware.hex (skips RISC-V GCC / Make)")
  if(FEMTORV_FIRMWARE_HEX AND EXISTS "${FEMTORV_FIRMWARE_HEX}")
    message(STATUS "FemtoRvSim: firmware hex override ${FEMTORV_FIRMWARE_HEX}")
    add_custom_command(
      OUTPUT "${_hex_out}"
      COMMAND "${CMAKE_COMMAND}" -E copy_if_different
              "${FEMTORV_FIRMWARE_HEX}" "${_hex_out}"
      DEPENDS "${FEMTORV_FIRMWARE_HEX}"
      COMMENT "FemtoRV firmware.hex from FEMTORV_FIRMWARE_HEX"
      VERBATIM)
  elseif(WIN32 OR FEMTORV_HEX_VIA_CMAKE)
    if(FEMTORV_RVGCC)
      femtorv_add_hex_via_cmake("${_hex_out}")
    else()
      femtorv_add_hex_via_golden("${_hex_out}")
    endif()
  else()
    femtorv_add_hex_via_make("${_hex_out}")
  endif()
  add_custom_target(firmware_hex DEPENDS "${_hex_out}")
  add_dependencies(sim_hello firmware_hex)

  add_custom_target(sim
    DEPENDS sim_hello firmware_hex
    COMMAND "${CMAKE_COMMAND}"
      -DEXE=$<TARGET_FILE:sim_hello>
      -DHEX=${_hex_out}
      -P "${RTL_LAB_CMAKE_DIR}/RunFemtoHello.cmake"
    COMMENT "Run FemtoRV Verilator hello (Hello, world / PASS / SIM DONE)"
    VERBATIM)

  add_test(NAME sim_hello
    COMMAND "${CMAKE_COMMAND}"
      -DEXE=$<TARGET_FILE:sim_hello>
      -DHEX=${_hex_out}
      -P "${RTL_LAB_CMAKE_DIR}/RunFemtoHello.cmake")
endfunction()
