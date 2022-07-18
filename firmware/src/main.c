
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

	// int dac = 1986;

	int mu_stat = mu_run_freq_detection(MU1, 1, 0xffff >> 1);

	if (mu_stat == MU_OK) {
		pp_printf("OK!\r\n");
		pp_printf("%d\r\n", MU1->stb_gen_period);
	} else {
		pp_printf("NOT OK!\r\n");
	}


	while (1);
	int dac = 0xffff >> 2;
	MU1->threshold = dac;

	int chan = 1;


	MU1->stb_gen_ctl = 5;
	delay(STB_GEN_WAIT_DELAY);

	if (MU1->stb_gen_ctl & STB_GEN_RDY) {
		pp_printf("ready\r\n");
		pp_printf("period: %d\r\n", MU1->stb_gen_period);
	} else {
		pp_printf("error\r\n");
	}


	// while (1) {
		// MU1->threshold = dac;
	// 	while (!MU1->threshold);
	// }

	while(1);

	// while(1) {
	// 	pp_printf("find edge with threshold %x\r\n", dac);
	// 	MU1->threshold = dac;
	// 	while (!MU1->threshold);
	// 	MU1->stb_gen_ctl = 5;
	// 	delay(STB_GEN_WAIT_DELAY);

	// 	if (MU1->stb_gen_ctl & STB_GEN_RDY) {
	// 		pp_printf("ready\r\n");
	// 		pp_printf("period: %d\r\n", MU1->stb_gen_period);
	// 		break;
	// 	} else {
	// 		dac += 0x10;
	// 	}
	// }

	MU1->ch_ctl_delta = (0x1 << 16) | (0x100);
	pp_printf("step %x\r\n", MU1->ch_ctl_delta);
	MU1->mu_ctl = 1;
	int cnt = 0;

	while(1) {
		if (MU1->mu_ch1_val & 1) {
			pp_printf("%d\r\n", MU1->mu_ch1_val >> 1);
			if (++cnt == 1024) break;
		}
	}

	while(1);
	MU1->threshold = dac;	

	return 0;
}
