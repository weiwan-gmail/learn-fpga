# FemtoRV teaching-SoC Verilator hello (step20.v + sim_main.cpp).
# Used by both cmake-system/ and cmake-conan/. Does not replace
# FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV Make / run_verilator.sh.

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/FindVerilatorKit.cmake")

set(FEMTORV_DIR "${RTL_LAB_REPO_ROOT}/FemtoRV")
set(FEMTORV_TUTORIAL_DIR
  "${FEMTORV_DIR}/TUTORIALS/FROM_BLINKER_TO_RISCV")
set(FEMTORV_LIBFEMTORV32 "${FEMTORV_DIR}/FIRMWARE/LIBFEMTORV32")

function(femtorv_sim_setup)
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  endif()
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  rtl_lab_find_verilator()
  include(CheckCXXCompilerFlag)

  find_program(FEMTORV_MAKE NAMES gmake make mingw32-make REQUIRED)
  find_program(FEMTORV_RVGCC NAMES riscv64-unknown-elf-gcc riscv-none-elf-gcc)
  if(NOT FEMTORV_RVGCC)
    message(FATAL_ERROR
      "riscv64-unknown-elf-gcc not found.\n"
      "Install gcc-riscv64-unknown-elf (Linux) or put a RISC-V GCC on PATH.\n"
      "CMake still calls the existing FemtoRV Make path for firmware.hex.")
  endif()
  message(STATUS "FemtoRvSim: RISC-V GCC=${FEMTORV_RVGCC}")
  message(STATUS "FemtoRvSim: MAKE=${FEMTORV_MAKE}")

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
  add_custom_command(
    OUTPUT "${_hex_out}"
    COMMAND "${FEMTORV_MAKE}" -C "${FEMTORV_TUTORIAL_DIR}" helloC.hex
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "${FEMTORV_TUTORIAL_DIR}/firmware.hex"
            "${_hex_out}"
    DEPENDS
      "${FEMTORV_TUTORIAL_DIR}/FIRMWARE/helloC.c"
      "${FEMTORV_TUTORIAL_DIR}/FIRMWARE/Makefile"
      "${FEMTORV_TUTORIAL_DIR}/Makefile"
    COMMENT "FemtoRV helloC.hex via existing Make (unchanged)"
    VERBATIM)
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
