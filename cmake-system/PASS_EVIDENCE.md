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

Windows MSVC (Visual Studio generator, no GNU make required):
[`WINDOWS.md`](WINDOWS.md). PC2023 configure no longer dies on
`FEMTORV_MAKE` / `gmake, make, mingw32-make`.

## Original Make still green

`FemtoRV/` Make / `run_verilator.sh` / `run.sh` were **not** rewritten
(host TB/harness only gained `_WIN32` / `_MSC_VER` preprocessor guards).

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

## cmake-system (default: Make hex, Linux)

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
-- FemtoRvSim: MAKE=/usr/bin/make
-- FemtoRvSim: RISC-V GCC=/bin/riscv64-unknown-elf-gcc
-- Executing Verilator...
-- Configuring done
```

`--target sim` / `ctest`: **Hello, world !** / **PASS** / **SIM DONE** /
**verilator_exit=0** / **ALL TESTS PASSED.** /
**100% tests passed, 0 tests failed out of 1** (`sim_hello`).

## Windows cmake hex path, proven on Linux

Same tree, no GNU make for hex (the PC2023 recipe):

```bash
cmake -S cmake-system -B build-system-cmakehex -DCMAKE_BUILD_TYPE=Release \
  -DFEMTORV_HEX_VIA_CMAKE=ON
cmake --build build-system-cmakehex --target sim
ctest --test-dir build-system-cmakehex --output-on-failure
```

Builds host `firmware_words` with the CMake C++ compiler, then
`cmake/BuildFemtoHelloHex.cmake` (RISC-V GCC + as/ld). Result:

```
SIM DONE after 69170 clock cycles
-- verilator_exit=0
-- ALL TESTS PASSED.
100% tests passed, 0 tests failed out of 1
```

Golden fallback (`cmake/firmware.helloC.hex`, used on Windows when RISC-V
GCC is missing):

```bash
cmake -S cmake-system -B build-system-golden -DCMAKE_BUILD_TYPE=Release \
  -DFEMTORV_FIRMWARE_HEX=cmake/firmware.helloC.hex
cmake --build build-system-golden --target sim
ctest --test-dir build-system-golden --output-on-failure
```

Same **69170** / **ALL TESTS PASSED.** / **100% tests passed**.
