
#include "dev/dev.h"
#include "pp_printf/pp-printf.h"


unsigned int delay(unsigned int n) {
	while (n > 0) n--;
	return n;
}

int main(void) {
	GPIOA->oe = 0xffffffff;
	GPIOA->out = 0x1;
	uart_init(UART1, 19200);
	pp_printf("Hello world!");
	while(1);
	return 0;
}
