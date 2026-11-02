#!/usr/bin/env bash
# Icarus / iverilog run for a teaching-SoC Verilog file.
# Usage: ./run.sh step20.v
set -euo pipefail
rm -f a.out
if [ -n "${2:-}" ]; then
  iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=10 -DCPU_FREQ=10 \
	   bench_iverilog.v "$1" "$2"
else
  iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=10 -DCPU_FREQ=10 \
	   bench_iverilog.v "$1"
fi
vvp a.out 2>&1 | tee sim_hello.last.log
