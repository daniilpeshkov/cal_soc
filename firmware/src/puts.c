#include "dev/dev.h"
// #include "dev/uart/wbuart32.h"

#define PRINTF_UART UART1

void _puts(const char *str) {
    const char *c = str;
    while (*c != '\0') {
        uart_putchar(PRINTF_UART, *c++);
    }
}