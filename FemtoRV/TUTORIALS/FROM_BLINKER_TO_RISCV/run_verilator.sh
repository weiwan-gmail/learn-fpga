#!/usr/bin/env bash
# Convert a teaching-SoC Verilog file to C++ with Verilator and run it.
# Usage: ./run_verilator.sh step20.v
# Optional $2 is reserved for an ELF overlay (see sim_main.cpp).
set -euo pipefail
mkdir -p obj_dir
(cd obj_dir && rm -f *.cpp *.o *.a VSOC) || true
verilator -CFLAGS '-I../../../FIRMWARE/LIBFEMTORV32 -DSTANDALONE_FEMTOELF' \
	  -DBENCH -DBOARD_FREQ=10 -DCPU_FREQ=10 -DPASSTHROUGH_PLL -Wno-fatal -Wno-WIDTHTRUNC \
	  --top-module SOC -cc -exe sim_main.cpp ../../FIRMWARE/LIBFEMTORV32/femto_elf.c "$1"
(cd obj_dir; make -f VSOC.mk)
# Tee UART + LEDS so `make test_verilator_hello` can grep PASS.
if [ -n "${2:-}" ]; then
  obj_dir/VSOC "$2" 2>&1 | tee sim_hello.last.log
else
  obj_dir/VSOC 2>&1 | tee sim_hello.last.log
fi
