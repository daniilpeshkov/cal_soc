#include "periph.h"
#include "uart.h"
#include "gpio.h"
#include "printf.h"


unsigned int delay(unsigned int n) {
	while (n > 0) n--;
	return n;
}

void main(void) {
	unsigned int tmp;	

	GPIOA->oe = 0xffffffff;
	GPIOA->out = 0x8a;

	while(1);

	uart_init(UART1, 9600L);
	tmp = 1;

	GPIOA->out = 0xaa;
	while (1) {

		if (UART1->fifo & 1) {
			tmp = UART1->rx_data;

			GPIOA->out += 1;
			_putchar('A');
		} 
	}
}
