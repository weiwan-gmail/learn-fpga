# Run the FemtoRV Verilator hello binary next to firmware.hex and require
# the same greps as FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/Makefile:
#   Hello, world / ^PASS$ / SIM DONE
if(NOT EXE OR NOT EXISTS "${EXE}")
  message(FATAL_ERROR "sim executable missing: '${EXE}'")
endif()
if(NOT HEX OR NOT EXISTS "${HEX}")
  message(FATAL_ERROR "firmware.hex missing: '${HEX}'")
endif()

get_filename_component(_hexdir "${HEX}" DIRECTORY)
get_filename_component(_exedir "${EXE}" DIRECTORY)
file(COPY "${HEX}" DESTINATION "${_exedir}")

execute_process(
  COMMAND "${EXE}"
  WORKING_DIRECTORY "${_hexdir}"
  RESULT_VARIABLE _rc
  OUTPUT_VARIABLE _out
  ERROR_VARIABLE _err)

set(_all "${_out}${_err}")
message(STATUS "FemtoRV sim stdout/stderr:\n${_all}")

if(_rc)
  message(FATAL_ERROR "sim exit ${_rc}")
endif()

if(NOT _all MATCHES "Hello, world")
  message(FATAL_ERROR "missing 'Hello, world' in sim output")
endif()
if(NOT _all MATCHES "(^|\n)PASS(\r?\n|$)")
  message(FATAL_ERROR "missing standalone PASS line in sim output")
endif()
if(NOT _all MATCHES "SIM DONE")
  message(FATAL_ERROR "missing 'SIM DONE' in sim output")
endif()

message(STATUS "verilator_exit=0")
message(STATUS "ALL TESTS PASSED.")
