# Windows CMake (PC2023 / MSVC)

Linux dual-tree is proven in [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).
This file is the PC2023 copy-paste for **cmake-system** (and the same
shared `cmake/FemtoRvSim.cmake` used by cmake-conan) with the **Visual
Studio** generator and the MSVC toolset.

FemtoRV Make / `run_verilator.sh` stay unchanged. The Verilator **cmake**
sim path does **not** require GNU make.

## Machine notes

| Item | Value |
|------|--------|
| Worker workspace | `D:\CursorWorker` |
| Generator | **Visual Studio 17 2022** (MSVC). `.\build_sim.ps1 -Generator "Visual Studio 17 2022"` |
| Conan | **2.34** (`cmake-conan` only) |
| Verilator | **[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)** or MSYS2 `mingw64` PE |
| Engine | **`verilator_bin.exe`** (PE32+, MZ). Never extensionless Perl `verilator`. |
| GNU make | optional. Discovered at `C:\msys64\usr\bin\make.exe` if present; **not** used to verilate or to build `sim_hello`. |
| Firmware hex | RISC-V GCC (`riscv64-unknown-elf-gcc` / xpack `riscv-none-elf-gcc`) rebuilds `helloC.hex`. If missing, CMake copies [`../cmake/firmware.helloC.hex`](../cmake/firmware.helloC.hex). |

PC2023 tip `e9eaa73` failed at configure with
`Could not find FEMTORV_MAKE ... gmake, make, mingw32-make` because
`find_program()` only searched `PATH`. CMake now looks in MSYS2
`usr/bin` / `mingw64/bin`, and Windows no longer requires make for this
target.

## withlimon / MSYS2 PE layout

Extract withlimon to a short path (`D:\verilator`), **or** use the MSYS2
PE already on PC2023:

```
C:\msys64\mingw64\bin\verilator_bin.exe     PE engine  ← drive this
C:\msys64\mingw64\bin\verilator             Perl driver, no extension — do not invoke
C:\msys64\mingw64\share\verilator\bin\verilator_bin.exe
                                           Perl wrapper with a .exe suffix — do not invoke
```

```
VERILATOR_ROOT = D:\verilator          (withlimon)
            or   C:\msys64\mingw64     (MSYS2 prefix; kit may be share/verilator)
PATH          += <that>\bin
```

The tarball does **not** ship `verilator-config.cmake`; shared
`cmake/FindVerilatorKit.cmake` uses `cmake/verilator-config.fallback.cmake`.
CMake MZ-checks `verilator_bin.exe` and walks up from
`VERILATOR_ROOT=share/verilator` to `mingw64\bin`.

## cmake-system (no Conan)

From PowerShell / x64 Native Tools (worker checkout):

```bat
cd /d D:\CursorWorker\learn-fpga
cd cmake-system
powershell -File .\build_sim.ps1 -Generator "Visual Studio 17 2022"
```

Or by hand:

```bat
set VERILATOR_ROOT=C:\msys64\mingw64
set PATH=%VERILATOR_ROOT%\bin;%PATH%
cmake -S cmake-system -B build-system -G "Visual Studio 17 2022"
cmake --build build-system --config Release --target sim
ctest --test-dir build-system -C Release --output-on-failure
```

Expect `Hello, world !` / `PASS` / `SIM DONE` / `ALL TESTS PASSED.`

`build_sim.ps1` searches, in order:

1. `D:\verilator\bin\verilator_bin.exe` (MZ)
2. `C:\msys64\mingw64\bin\verilator_bin.exe` (MZ)
3. `$VERILATOR_ROOT\bin` and parents (skip Perl wrappers)
4. `verilator_bin.exe` on PATH if it is a PE

It also prepends MSYS2 `usr\bin` when `make.exe` is there, and prepends a
RISC-V GCC bindir (PATH, MSYS2, or xpack) when found.

## Firmware hex (no GNU make)

On Windows, `femtorv_sim_setup()` does **not** call `make helloC.hex`:

1. If `-DFEMTORV_FIRMWARE_HEX=` is set, copy that file.
2. Else if a RISC-V GCC is found, build host `firmware_words` with **MSVC**
   and assemble/link `helloC.c` + `start.S` via
   [`../cmake/BuildFemtoHelloHex.cmake`](../cmake/BuildFemtoHelloHex.cmake).
3. Else copy the committed golden hex (same image as Linux `helloC.bram.hex`).

Linux still uses the original Make path unless you pass
`-DFEMTORV_HEX_VIA_CMAKE=ON` (that flag is how this tree is regression-tested
on Linux).

Host C/C++ differences use preprocessor guards (`_MSC_VER`, `_WIN32`) in
`sim_main.cpp`, `femto_elf.c`, and `firmware_words.cpp` (no POSIX `unistd.h`
/ 3-arg `main` on Windows; ELF `fopen(..., "rb")` on `_WIN32`).

## cmake-conan (Conan 2.34 + local recipe)

```bat
cd /d D:\CursorWorker\learn-fpga\cmake-conan
powershell -File .\build_sim.ps1 -Generator "Visual Studio 17 2022"
```

`cmake-conan\build_sim.ps1` `conan export`s `recipes/verilator` and uses
`--no-remote`. Profile: `cmake-conan/profiles/windows-msvc`.

## MSVC

`CheckCXXCompilerFlag` before `verilate()`, then strip `-fcoroutines*`.
`sim_hello` (and `firmware_words` when built) get `_CRT_SECURE_NO_WARNINGS`,
`NOMINMAX`, `/bigobj`. Do **not** run `share\verilator\bin\verilator_bin.exe`
(Perl wrapper with a `.exe` suffix).

## Do not

- Do not run extensionless `bin\verilator` from Explorer or CMD.
- Do not point CMake at the Perl driver.
- Do not require GNU make on PATH for `cmake-system` / `cmake-conan` sim.
- Do not change `FemtoRV/` Make / `run_verilator.sh`.
