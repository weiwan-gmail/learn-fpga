# cmake-system PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu, x86_64).
FemtoRV teaching-SoC Verilator hello (`step20.v` + `helloC.c` hex).

| Tool | Version |
|------|---------|
| CMake | 3.28.3 |
| g++ | 13.3.0 (`PreferUnixGcc`) |
| Verilator | 5.020 (Debian 5.020-1), `verilator_bin` at `/bin/verilator_bin`, kit `/usr/share/verilator` |
| RISC-V GCC | `riscv64-unknown-elf-gcc` 13.2.0 |
| Conan | not used in this tree |

Windows (withlimon `verilator_bin.exe`) is a **follow-up**: [`WINDOWS.md`](WINDOWS.md).

## Original Make still green

`FemtoRV/` Make / `run_verilator.sh` / `run.sh` were **not** edited.

```
cd FemtoRV && make test_verilator_hello
...
LEDS: 10101
Hello, world !
PASS
LEDS: 11111
EBREAK (SYSTEM) — CPU halted
- step20.v:288: Verilog $finish
SIM DONE after 69170 clock cycles
verilator_exit=0
ALL TESTS PASSED.
```

`make test_hello` (Icarus): `Hello, world !` / `PASS` / `iverilog_exit=0` / `ALL TESTS PASSED.`

## cmake-system

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

Configure:

```
-- PreferUnixGcc: CMAKE_CXX_COMPILER=/usr/bin/g++
-- FindVerilatorKit: VERILATOR_BIN=/bin/verilator_bin
-- FindVerilatorKit: VERILATOR_ROOT=/usr/share/verilator
-- FemtoRvSim: RISC-V GCC=/usr/bin/riscv64-unknown-elf-gcc
-- Executing Verilator...
-- Configuring done
```

`--target sim`:

```
LEDS: 10101
Hello, world !
PASS
LEDS: 11111
EBREAK (SYSTEM) — CPU halted
- /workspace/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/step20.v:288: Verilog $finish
SIM DONE after 69170 clock cycles
-- verilator_exit=0
-- ALL TESTS PASSED.
[100%] Built target sim
```

`ctest`: **100% tests passed, 0 tests failed out of 1** (`sim_hello`).
