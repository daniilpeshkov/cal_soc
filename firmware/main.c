#include "reg_def.h"
#include "uart.h"
#include "printf.h"

#define RGPIOA_OUT	*((int*) 0x02000004)
#define RGPIOA_OE	*((int*) 0x02000008)

unsigned int delay(unsigned int n) {
	while (n > 0) n--;
	return n;
}

void main(void) {
	unsigned int tmp;	

	RGPIOA_OE = 0xffffffff;
	RGPIOA_OUT = 0xaa;

	uart_init(UART1, 9600L);
	tmp = 1;

	RGPIOA_OUT = 0;
	while (1) {

		if (UART1->fifo & 1) {
			tmp = UART1->rx_data;
			RGPIOA_OUT += 1;
			_putchar('A');
			// _putchar('B');
			// for (int i = 0; i < 10; i++) {
				// _putchar('U');
			// }
		} 
	}
}
