# FemtoRV learning index / 学习入口

Primary tutorial (Chinese, for Wei): **[TUTORIAL_zh.md](TUTORIAL_zh.md)**
Shorter English summary: **[TUTORIAL.md](TUTORIAL.md)**
Proven command logs: **[logs/](logs/)**

This fork (`weiwan-gmail/learn-fpga`, work on **develop**, parent
[BrunoLevy/learn-fpga](https://github.com/BrunoLevy/learn-fpga)) keeps the
original Episode I Icarus + firmware-hex flow and makes the **already-present
Verilator C++ driver** work on a modern Linux box. Production cores in
`FemtoRV/RTL/PROCESSOR/` are not rewritten.

**Why hex + Verilator, not a new C ISS:** the teaching SoC already compiles C
(`helloC.c`) to `firmware.hex`, `$readmemh`s it into BRAM, and `sim_main.cpp`
only toggles `CLK`. That *is* C firmware co-sim for this core. A separate
instruction-set simulator would be a second CPU.

## Exact commands (reproduced in `docs/logs/`)

Install tools (Ubuntu/Debian):

```bash
sudo apt-get install -y iverilog verilator gcc-riscv64-unknown-elf build-essential
cd FemtoRV
make toolchain-info
```

### 1) Small C hello (documented demo)

```bash
cd FemtoRV
make test_verilator_hello
# expect: Hello, world ! / PASS / EBREAK / SIM DONE / ALL TESTS PASSED.
```

Icarus (same hex, same TB protocol):

```bash
make test_hello
# expect: Hello, world ! / PASS / ALL TESTS PASSED.
```

### 2) Upstream teaching scripts (unchanged names)

```bash
cd FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV
make -C FIRMWARE ARCH=rv32i ABI=ilp32 helloC.bram.hex
./run_verilator.sh step20.v
./run.sh step20.v
```

`hello.S` still builds (`make hello.bram.hex`) but **loops** — not the PASS demo.

Full-SoC `make BENCH` (GLFW OLED) and LiteX are optional; see TUTORIAL_zh §8.

## How to read PASS / FAIL

| Check | Meaning |
|-------|---------|
| UART `$write` of each store to `0x400008` | printed character |
| stdout `PASS` | `helloC.c` finished the greeting |
| `EBREAK (SYSTEM)` | `start.S` ran `ebreak` after `main` |
| `SIM DONE after N clock cycles` | Verilator `$finish`, not timeout |
| `verilator_exit=0` / `ALL TESTS PASSED.` | Makefile grepped the log |

## Next cores on the ladder

After this tree is green:

1. **darkriscv** — a from-scratch pipelined RV32; compare with FemtoRV’s
   multi-cycle `step20.v` and PicoRV32’s single-file `picorv32.v`.
2. **SERV** — bit-serial RISC-V; same ISA, radically different microarchitecture.

See the last section of [TUTORIAL_zh.md](TUTORIAL_zh.md).
