#ifndef _REG_DEF_H_
#define _REG_DEF_H_

#define UART1_BASE 0x03000000 

typedef struct {
    volatile unsigned int setup;
    volatile unsigned int fifo;
    volatile unsigned int rx_data;
    volatile unsigned int tx_data;        
} UART_TypeDef;

#define UART1   ((UART_TypeDef*) UART1_BASE)

#endif