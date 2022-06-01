
#include "dev/dev.h"
#include "pp_printf/pp-printf.h"

// __attribute__((used)) 

void delay(unsigned int n)  {
	while (--n) asm("");
}

int main(void) {
	uart_init(UART1, 19200);

	pp_printf("WR Calibrator \r\n");

	int dac = 0x4d93; 
	// int dac = 0;

	MU1->threshold = dac;	

	MU1->stb_gen_ctl = 1;
	while (1) {
		// pp_printf("reg %x\r\n", MU1->stb_gen);

		// MU1->threshold = dac;	
		// while (!MU1->threshold);
		if (MU1->stb_gen_ctl & STB_GEN_ERR) {
			pp_printf("err\r\n");
			delay(900000);
		} else if (MU1->stb_gen_ctl & STB_GEN_RDY) {
			pp_printf("%d\r\n", MU1->stb_gen_period);
			break;
		}

	}

	while(1);
	return 0;
}
