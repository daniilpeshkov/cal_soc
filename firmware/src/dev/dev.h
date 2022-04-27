#ifndef _DEV_H_
#define _DEV_H

#define F_CPU 12000000L

#include "gpio/gpio.h"
#include "uart/wbuart32.h"

#define UART1_BASE 0x03000000 
#define GPIOA_BASE 0x02000000


#define UART1   ((UART_TypeDef*) UART1_BASE)

#define GPIOA   ((GPIO_TypeDef*) GPIOA_BASE)

#endif