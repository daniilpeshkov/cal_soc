
#include "dev/dev.h"
#include "pp_printf/pp-printf.h"

// __attribute__((used)) 

#define STB_GEN_WAIT_DELAY 1000000

void delay(unsigned int n)  {
	while (--n) asm("");
}

void main(void) {
	uart_init(UART1, 19200);

	pp_printf("WR Calibrator \r\n");

	int mu_stat = mu_run_freq_detection(MU1, 1, 0xffff >> 1);

	if (mu_stat == MU_OK) {
		pp_printf("OK!\r\n");
		pp_printf("%d\r\n", MU1->stb_gen_period);
	} else {
		pp_printf("NOT OK!\r\n");
	}


	while (1);
}
