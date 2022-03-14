#ifndef _REG_DEF_H_
#define _REG_DEF_H_

#include "gpio.h"
#include "uart.h"

#define UART1_BASE 0x03000000 
#define GPIOA_BASE 0x02000000


#define UART1   ((UART_TypeDef*) UART1_BASE)

#define GPIOA   ((GPIO_TypeDef*) GPIOA_BASE)

#endif