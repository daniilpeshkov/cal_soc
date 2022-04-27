#ifndef _WBUART32_H_
#define _WBUART32_H_

#define F_UART 12000000

typedef struct {
    volatile unsigned int setup;
    volatile unsigned int fifo;
    volatile unsigned int rx_data;
    volatile unsigned int tx_data;        
} UART_TypeDef;

void uart_init(UART_TypeDef *uart_base, unsigned int baud);

void uart_putchar(UART_TypeDef *uart_base, char c);

#endif