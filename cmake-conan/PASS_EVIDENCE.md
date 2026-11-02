# cmake-conan PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu, x86_64).
Same FemtoRV `sim` target as [`../cmake-system/PASS_EVIDENCE.md`](../cmake-system/PASS_EVIDENCE.md).

| Tool | Version |
|------|---------|
| CMake | 3.28.3 |
| g++ | 13.3.0 (`PreferUnixGcc`; `conan profile detect` guessed clang, provider used **auto-cmake → gcc 13**) |
| Verilator | local recipe `verilator/5.052` **packaged the system 5.020 kit** (did not rebuild from source) |
| RISC-V GCC | `riscv64-unknown-elf-gcc` 13.2.0 |
| Conan | **2.34.0** (`pip install --user conan`) — same major/minor as PC2023 |

Windows MSVC (Conan 2.34 + withlimon / MSYS2 `verilator_bin.exe` PE, no
GNU make required): [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md).

## Configure

```bash
export PATH="$HOME/.local/bin:$PATH"
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
```

```
======== Installing packages ========
-------- Installing package verilator/5.052 ...
Calling package()
package(): Packaged 1 '.cmake' file: verilator-config.cmake
...
Install finished successfully
-- FindVerilatorKit: Conan package folder /home/ubuntu/.conan2/p/b/veril.../p
-- FindVerilatorKit: VERILATOR_BIN=.../p/bin/verilator_bin
-- FindVerilatorKit: VERILATOR_ROOT=.../p
-- Executing Verilator...
-- Configuring done
```

## sim / ctest

```bash
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
```

`--target sim`:

```
LEDS: 10101
Hello, world !
PASS
LEDS: 11111
EBREAK (SYSTEM) — CPU halted
SIM DONE after 69170 clock cycles
-- verilator_exit=0
-- ALL TESTS PASSED.
[100%] Built target sim
```

`ctest`: **100% tests passed, 0 tests failed out of 1**.

Re-run **2026-11-02** after the Windows MSVC cmake-sim change (same Linux
VM): configure still packages system Verilator 5.020 as `verilator/5.052`,
`--target sim` prints `Hello, world !` / `PASS` / `SIM DONE` /
`ALL TESTS PASSED.`, `ctest` **100% tests passed, 0 tests failed out of 1**.
