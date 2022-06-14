
#include "dev/dev.h"
#include "pp_printf/pp-printf.h"

// __attribute__((used)) 

#define STB_GEN_WAIT_DELAY 1000000

void delay(unsigned int n)  {
	while (--n) asm("");
}

int main(void) {
	uart_init(UART1, 19200);

	pp_printf("WR Calibrator \r\n");

	int dac = 0x100;
	while(1) {
		pp_printf("find edge with threshold %x\r\n", dac);
		MU1->threshold = dac;
		while (!MU1->threshold);
		MU1->stb_gen_ctl = 5;
		delay(STB_GEN_WAIT_DELAY);

		if (MU1->stb_gen_ctl & STB_GEN_RDY) {
			pp_printf("ready\r\n");
			pp_printf("period: %d\r\n", MU1->stb_gen_period);
			break;
		} else {
			dac += 0x10;
		}
	}

	MU1->mu_ctl = 1;
	while(1);

	MU1->threshold = dac;	

	return 0;
}
