/*
 * One-shot C hello for the teaching SoC (step20.v / pipeline*.v).
 *
 * Assembly hello.S loops forever so a simulator never exits. This program
 * prints once, then returns to start.S, which executes ebreak. Under `BENCH`
 * that SYSTEM instruction $finish()es the simulation.
 *
 * UART is memory-mapped at IO_BASE (gp), same as putchar.S:
 *   0x400008  IO_UART_DAT   write character
 *   0x400010  IO_UART_CNTL  bit 9 = TX busy
 */

#include "io.h"

static void uart_putc(int c)
{
   IO_OUT(IO_UART_DAT, (unsigned)(c & 0xff));
   while (IO_IN(IO_UART_CNTL) & (1u << 9)) {
      /* wait until the emitter UART accepts the next byte */
   }
}

static void uart_puts(const char *s)
{
   while (*s) {
      uart_putc(*s++);
   }
}

int main(void)
{
   IO_OUT(IO_LEDS, 0x15); /* 10101 — visible as LEDS: in the C++ bench */
   uart_puts("Hello, world !\n");
   uart_puts("PASS\n");
   IO_OUT(IO_LEDS, 0x1f);
   return 0;
}
