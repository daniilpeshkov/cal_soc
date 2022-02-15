#ifndef _UART_H_
#define _UART_H_

#include "reg_def.h"

void uart_init(UART_TypeDef *uart_base, unsigned int baud);

#endif