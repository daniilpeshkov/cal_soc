#include "printf.h"
#include "reg_def.h"

#define PRINTF_UART UART1

void _putchar(char character) {
    while (!(PRINTF_UART->fifo & (1<<16))) {}
    PRINTF_UART->tx_data = character & 0xff;
}
