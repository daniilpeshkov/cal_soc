#include "uart.h"
#include "global_defines.h"

void uart_init(UART_TypeDef *uart_base, unsigned int baud) {
	uart_base->setup = F_CPU / baud;
}