# Windows CMake (follow-up)

Linux dual-tree is proven in [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).
This file is the PC2023 copy-paste for a later Windows run. FemtoRV Make
paths stay unchanged.

## Machine notes

| Item | Value |
|------|--------|
| Worker workspace | `D:\CursorWorker` |
| Conan | **2.34** (`cmake-conan` only) |
| Verilator | **[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)** |
| Engine | **`verilator_bin.exe`** (PE32+). Never extensionless Perl `verilator`. |
| Firmware hex | still `make helloC.hex` (RISC-V GCC). WSL or xpack on PATH is the follow-up. |

Extract withlimon to a short path (`D:\verilator`):

```
D:\verilator\bin\verilator_bin.exe     PE engine  ← drive this
D:\verilator\bin\verilator             Perl driver, no extension — do not invoke
```

The tarball does **not** ship `verilator-config.cmake`; shared
`cmake/FindVerilatorKit.cmake` uses `cmake/verilator-config.fallback.cmake`.

```
VERILATOR_ROOT = D:\verilator
PATH          += D:\verilator\bin
```

```bat
cd cmake-system
powershell -File .\build_sim.ps1
```

`cmake-conan\build_sim.ps1` `conan export`s `recipes/verilator` and uses
`--no-remote`. Profile: `cmake-conan/profiles/windows-msvc`.

MSVC: `CheckCXXCompilerFlag` before `verilate()`, then strip `-fcoroutines*`.
Do **not** run `share\verilator\bin\verilator_bin.exe` (Perl wrapper with a
`.exe` suffix).
