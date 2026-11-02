# Captured command logs

Real terminal output from the documented FemtoRV teaching-SoC sim, not
hand-written transcripts. Regenerated with:

```bash
cd FemtoRV
make toolchain-info
make test_verilator_hello
make test_hello
```

| File | What |
|------|------|
| `01-inspect.txt` | `make toolchain-info` |
| `02-build-hello.txt` | `helloC.bram.hex` (C → ELF → hex) |
| `03-verilator-build.txt` | Verilator 5 compile of `step20.v` |
| `04-iverilog-hello.txt` | Icarus run (`make test_hello`) |
| `05-verilator-hello.txt` | Verilator run + `ALL TESTS PASSED.` |
