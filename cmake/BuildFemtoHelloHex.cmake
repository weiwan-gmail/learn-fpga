# Build-time helper: helloC.c + start.S → firmware.hex without GNU make.
# Invoked as `cmake -P` from FemtoRvSim.cmake on Windows / FEMTORV_HEX_VIA_CMAKE.
#
# Required -D:
#   RVGCC, FW_DIR, HEX_OUT, WORDS_EXE, WORK_DIR

if(NOT RVGCC OR NOT FW_DIR OR NOT HEX_OUT OR NOT WORDS_EXE OR NOT WORK_DIR)
  message(FATAL_ERROR
    "BuildFemtoHelloHex: need -DRVGCC= -DFW_DIR= -DHEX_OUT= -DWORDS_EXE= -DWORK_DIR=")
endif()
if(NOT EXISTS "${RVGCC}")
  message(FATAL_ERROR "BuildFemtoHelloHex: RVGCC not found: ${RVGCC}")
endif()
if(NOT EXISTS "${WORDS_EXE}")
  message(FATAL_ERROR "BuildFemtoHelloHex: firmware_words not found: ${WORDS_EXE}")
endif()
if(NOT EXISTS "${FW_DIR}/helloC.c" OR NOT EXISTS "${FW_DIR}/start.S"
   OR NOT EXISTS "${FW_DIR}/bram.ld")
  message(FATAL_ERROR "BuildFemtoHelloHex: missing helloC.c / start.S / bram.ld in ${FW_DIR}")
endif()

get_filename_component(_bin "${RVGCC}" DIRECTORY)
get_filename_component(_nam "${RVGCC}" NAME_WE)
string(REGEX REPLACE "-gcc$" "" _pfx "${_nam}")

# RISC-V toolchain DLLs (xpack / MinGW) live next to gcc.exe.
if(CMAKE_HOST_WIN32)
  set(ENV{PATH} "${_bin};$ENV{PATH}")
endif()

set(_as "${_bin}/${_pfx}-as")
set(_ld "${_bin}/${_pfx}-ld")
if(CMAKE_HOST_WIN32)
  if(NOT EXISTS "${_as}" AND EXISTS "${_as}.exe")
    set(_as "${_as}.exe")
  endif()
  if(NOT EXISTS "${_ld}" AND EXISTS "${_ld}.exe")
    set(_ld "${_ld}.exe")
  endif()
endif()

file(MAKE_DIRECTORY "${WORK_DIR}")
set(_hello_o "${WORK_DIR}/helloC.o")
set(_start_o "${WORK_DIR}/start.o")
set(_elf "${WORK_DIR}/helloC.bram.elf")

# Match FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/FIRMWARE/Makefile RVCFLAGS
# (ARCH=rv32i ABI=ilp32, -O2, -ffreestanding).
set(_cflags
  -I "${FW_DIR}"
  -O2 -fno-pic -march=rv32i -mabi=ilp32
  -fno-stack-protector -w -mno-relax -ffreestanding -std=gnu99)

execute_process(
  COMMAND "${RVGCC}" ${_cflags} -c "${FW_DIR}/helloC.c" -o "${_hello_o}"
  RESULT_VARIABLE _rc
  OUTPUT_VARIABLE _out
  ERROR_VARIABLE _err)
if(_rc)
  message(FATAL_ERROR "BuildFemtoHelloHex: compile helloC.c failed (${_rc}):\n${_out}${_err}")
endif()

# Assemble start.S. Prefer the matching GNU as; gcc -c also works.
if(EXISTS "${_as}")
  execute_process(
    COMMAND "${_as}" -march=rv32i -mabi=ilp32 -mno-relax
            "${FW_DIR}/start.S" -o "${_start_o}"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
else()
  execute_process(
    COMMAND "${RVGCC}" -march=rv32i -mabi=ilp32 -mno-relax
            -c "${FW_DIR}/start.S" -o "${_start_o}"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
endif()
if(_rc)
  message(FATAL_ERROR "BuildFemtoHelloHex: assemble start.S failed (${_rc}):\n${_out}${_err}")
endif()

# bram.ld places `start.o (.text)` first — link by basename from WORK_DIR.
if(EXISTS "${_ld}")
  execute_process(
    COMMAND "${_ld}" -T "${FW_DIR}/bram.ld" -m elf32lriscv -nostdlib --no-relax
            helloC.o start.o -o helloC.bram.elf
    WORKING_DIRECTORY "${WORK_DIR}"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
else()
  execute_process(
    COMMAND "${RVGCC}" -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding
            -Wl,-T,${FW_DIR}/bram.ld -Wl,--no-relax -Wl,-m,elf32lriscv
            -o helloC.bram.elf start.o helloC.o
    WORKING_DIRECTORY "${WORK_DIR}"
    RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
endif()
if(_rc)
  message(FATAL_ERROR "BuildFemtoHelloHex: link helloC.bram.elf failed (${_rc}):\n${_out}${_err}")
endif()

execute_process(
  COMMAND "${WORDS_EXE}" "${_elf}" -ram 6144 -max_addr 6144 -out "${HEX_OUT}"
  RESULT_VARIABLE _rc OUTPUT_VARIABLE _out ERROR_VARIABLE _err)
if(_rc)
  message(FATAL_ERROR
    "BuildFemtoHelloHex: firmware_words failed (${_rc}):\n${_out}${_err}")
endif()
message(STATUS "BuildFemtoHelloHex: wrote ${HEX_OUT}")
