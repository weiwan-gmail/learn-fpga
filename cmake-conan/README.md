# cmake-conan — Conan 2 + local Verilator recipe

Thin wrapper, same FemtoRV `sim` target as [`../cmake-system/`](../cmake-system/).
Shared helpers: [`../cmake/FemtoRvSim.cmake`](../cmake/FemtoRvSim.cmake).
Does **not** change `FemtoRV/` Make.

| Path | Role |
|------|------|
| `CMakeLists.txt` | `PreferUnixGcc` → export local recipe → `conan_provider.cmake` → `FemtoRvSim` |
| `conanfile.py` | `tool_requires("verilator/5.052")` |
| `recipes/verilator/` | withlimon PE on Windows; packages the system kit on Linux |
| `profiles/` | `linux-gcc`, `windows-msvc` |

```bash
export PATH="$HOME/.local/bin:$PATH"   # pip --user conan (proved 2.34.0)
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
```

If Conan is missing, use `cmake-system/` instead.

Linux evidence: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).
Windows MSVC: [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md).
