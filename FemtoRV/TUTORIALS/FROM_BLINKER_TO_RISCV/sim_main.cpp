#if defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS)
#  define _CRT_SECURE_NO_WARNINGS
#endif

#include "VSOC.h"
#include "verilated.h"
#include "femto_elf.h"
#include <cstdlib>
#include <iostream>
#include <memory>

#if defined(_WIN32)
#  include <io.h>
#  include <process.h>
#else
#  include <unistd.h>
#endif

static const uint64_t DEFAULT_MAX_CYCLES = 2000000;

int main(int argc, char** argv
#if !defined(_WIN32)
         , char** env
#endif
         ) {
#if !defined(_WIN32)
   (void)env;
#endif
   const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
   contextp->commandArgs(argc, argv);

   VSOC top{contextp.get()};
   top.CLK = 0;
   CData prev_LEDS = 0;

   uint64_t max_cycles = DEFAULT_MAX_CYCLES;
   if (const char* e = std::getenv("FEMTORV_MAX_CYCLES")) {
      max_cycles = std::strtoull(e, nullptr, 0);
   }

   // Call eval() so that $readmemh()/initial blocks run before the clock.
   top.eval();

   // Optional ELF overlay (kept from upstream; hex via $readmemh is the
   // documented path). Hierarchical RAM access is board- and Verilator-
   // version specific, so it stays commented.
   /*
   if(argc > 1) {
       Elf32Info elf;
       void* simulated_RAM = nullptr;
       int elf_status = elf32_load_at(argv[1], &elf, simulated_RAM);
       (void)elf_status;
   }
   */

   uint64_t half_cycles = 0;
   while (!contextp->gotFinish()) {
      top.CLK = !top.CLK;
      top.eval();
      half_cycles++;
      if (top.CLK == 0) {
         if (prev_LEDS != top.LEDS) {
            std::cout << "LEDS: ";
            for (int i = 0; i < 5; ++i) {
               std::cout << ((top.LEDS >> (4 - i)) & 1);
            }
            std::cout << std::endl;
         }
         prev_LEDS = top.LEDS;
      }
      if ((half_cycles / 2) > max_cycles) {
         std::cerr << "TIMEOUT after " << (half_cycles / 2)
                   << " clock cycles" << std::endl;
         return 2;
      }
   }
   std::cout << "SIM DONE after " << (half_cycles / 2)
             << " clock cycles" << std::endl;
   return 0;
}
