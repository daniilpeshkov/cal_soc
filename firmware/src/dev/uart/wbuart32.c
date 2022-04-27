#include "wbuart32.h"

void uart_init(UART_TypeDef *uart_base, unsigned int baud) {
	uart_base->setup = F_UART / baud;
}

void uart_putchar(UART_TypeDef *uart_base, char c) {
    while (!(uart_base->fifo & (1<<16))) {}
    uart_base->tx_data = c;
}