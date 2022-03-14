#ifndef _UART_H_
#define _UART_H_

typedef struct {
    volatile unsigned int setup;
    volatile unsigned int fifo;
    volatile unsigned int rx_data;
    volatile unsigned int tx_data;        
} UART_TypeDef;

void uart_init(UART_TypeDef *uart_base, unsigned int baud);

#endif