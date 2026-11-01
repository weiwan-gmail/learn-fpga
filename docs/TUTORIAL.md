# FemtoRV tutorial (English summary)

Chinese primary write-up: **[TUTORIAL_zh.md](TUTORIAL_zh.md)**
Command index: **[LEARNING.md](LEARNING.md)**
Real command output: **[logs/](logs/)**

This fork (`weiwan-gmail/learn-fpga`, work on **develop**, parent
[BrunoLevy/learn-fpga](https://github.com/BrunoLevy/learn-fpga)) keeps the
original teaching SoC and FPGA flows. It makes the **already-present**
Verilator + `firmware.hex` path practical on a modern Linux box. Production
CPU RTL (`FemtoRV/RTL/PROCESSOR/*.v`) is not rewritten.

**Why hex + Verilator, not a new C ISS:** Episode I already compiles C to
`firmware.hex`, `$readmemh`s it into BRAM, and `sim_main.cpp` only toggles
`CLK`. That *is* C firmware co-sim for this core.

## Proven commands

```bash
sudo apt-get install -y iverilog verilator gcc-riscv64-unknown-elf build-essential
cd FemtoRV
make toolchain-info
make test_verilator_hello    # C hello world
make test_hello              # same hex on Icarus
```

`makefile.inc` prefers `riscv64-unknown-elf-gcc` on PATH (Ubuntu package)
over downloading the SiFive tarball. Force the tarball with
`USE_BUNDLED_TOOLCHAIN=1`.

## Pass/fail (from `docs/logs/`)

**Verilator hello** (`docs/logs/05-verilator-hello.txt`):

```
LEDS: 10101
Hello, world !
PASS
LEDS: 11111
EBREAK (SYSTEM) — CPU halted
SIM DONE after 69170 clock cycles
verilator_exit=0
ALL TESTS PASSED.
```

**Icarus hello** (`docs/logs/04-iverilog-hello.txt`): same UART text, then
`iverilog_exit=0` / `ALL TESTS PASSED.`

Firmware protocol: `helloC.c` prints and returns; `start.S` executes
`ebreak`; under `BENCH` that SYSTEM instruction `$finish()`es the sim.
Do not use `hello.S` as the green command — it loops forever.

## What this ladder step teaches

After tinyriscv (3-stage + RIB) and picorv32 (single-file + `mem_valid/ready`):

- A spec-derived, readable RV32I you can grow from a blinker (`step20.v`)
- Your own 6KiB BRAM + `0x400000` IO page + linker script
- GNU C as a first-class citizen (`start.S` → `main`, tiny printf, hex load)

Not in the green path: Episode II pipeline, GLFW FemtoSoC `make BENCH`, LiteX.

## Next cores

1. **darkriscv** — pipelined RV32 from scratch; compare coding style.
2. **SERV** — bit-serial ALU; same ISA, opposite microarchitecture.
