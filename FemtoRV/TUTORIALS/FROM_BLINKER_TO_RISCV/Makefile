# Teaching-SoC simulation (Episode I step20).
#
#   make toolchain-info
#   make test_verilator_hello   # documented green command
#   make test_hello             # same hex on Icarus
#
# Does not rewrite RTL/PROCESSOR/*.v. Firmware is C → ELF → firmware.hex
# loaded with $readmemh, the same path as the original tutorial.

TUTORIAL_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
FW_DIR       := $(TUTORIAL_DIR)FIRMWARE

SIM_ARCH = ARCH=rv32i ABI=ilp32 OPTIMIZE=-Os DEVICES= RAM_SIZE=6144 BOARD=sim

.PHONY: toolchain-info helloC.hex test_verilator_hello test_hello \
        sim-hello clean-sim

toolchain-info:
	@echo "ARCH=rv32i ABI=ilp32 (teaching SoC step20.v)"
	@echo -n "riscv64-unknown-elf-gcc: "; riscv64-unknown-elf-gcc --version 2>/dev/null | head -1 || echo "not found"
	@echo -n "Verilator: "; verilator --version 2>/dev/null || echo "not found"
	@echo -n "Icarus: "; iverilog -V 2>/dev/null | head -1 || echo "not found"
	@$(MAKE) -C $(FW_DIR) $(SIM_ARCH) show_config

helloC.hex:
	$(MAKE) -C $(FW_DIR) $(SIM_ARCH) helloC.bram.hex

# C hello → hex → Verilator. Expect "Hello, world !" then "PASS".
test_verilator_hello sim-hello: helloC.hex
	./run_verilator.sh step20.v
	@grep -q "Hello, world" sim_hello.last.log
	@grep -q "^PASS$$" sim_hello.last.log
	@grep -q "SIM DONE" sim_hello.last.log
	@echo "verilator_exit=0"
	@echo "ALL TESTS PASSED."

test_hello: helloC.hex
	./run.sh step20.v
	@grep -q "Hello, world" sim_hello.last.log
	@grep -q "^PASS$$" sim_hello.last.log
	@echo "iverilog_exit=0"
	@echo "ALL TESTS PASSED."

clean-sim:
	$(MAKE) -C $(FW_DIR) clean
	rm -rf obj_dir a.out firmware.hex firmware.txt sim_hello.last.log
	rm -f FIRMWARE/helloC.bram.elf FIRMWARE/helloC.o FIRMWARE/helloC.bram.hex
