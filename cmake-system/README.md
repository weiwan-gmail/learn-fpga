# cmake-system — system Verilator (no Conan)

Thin wrapper. Shared helpers: [`../cmake/FemtoRvSim.cmake`](../cmake/FemtoRvSim.cmake),
[`../cmake/FindVerilatorKit.cmake`](../cmake/FindVerilatorKit.cmake).
Does **not** change `FemtoRV/` Make or `run_verilator.sh`.

Target: **`sim`** — Episode I `step20.v` + `helloC.c` hex (same greps as
`make test_verilator_hello`).

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

Linux evidence: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).
Windows (withlimon `verilator_bin.exe`): [`WINDOWS.md`](WINDOWS.md) follow-up.
Conan tree: [`../cmake-conan/`](../cmake-conan/). Index: [`../CMAKE.md`](../CMAKE.md).
