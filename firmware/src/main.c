
#include "dev/dev.h"
#include "pp_printf/pp-printf.h"

// __attribute__((used)) 

#define STB_GEN_WAIT_DELAY 1000000

void delay(unsigned int n)  {
	while (--n) asm("");
}


void test_chan (char master_ch) {

	int mu_stat = mu_run_freq_detection(MU1, master_ch, MU_CLK_EXT, (0xffff >> 3) + 100);

	if (mu_stat != MU_OK) {
		pp_printf("can not detect signal from master\r\n");
		while (1);
	} else {
		pp_printf("stb ready\r\n");
	}


    MU1->skew_mes_ctl = 0;
    MU1->skew_mes_ctl = ((master_ch & 1) << 1) | 1;

    while (!(MU1->skew_mes_ctl & SKEW_CTL_RDY) & !(MU1->skew_mes_ctl & SKEW_CTL_ERR));
    unsigned int tmp = MU1->skew_mes_ctl;

	if (MU1->skew_mes_ctl & SKEW_CTL_RDY) {
		pp_printf("succes\r\n");
		unsigned int delay = (tmp >> 6);
		pp_printf("delay  : 	%d ps \r\n", (delay & 0x3ff) * 10);
		pp_printf("offset : 	%d ps \r\n", ((delay >> 10) * 10));
	} else {
		pp_printf("err: 		%x \r\n", (tmp & SKEW_CTL_ERR)>>3);

		unsigned int delay = (tmp >> 6);
		pp_printf("delay  : 	%d ps \r\n", (delay & 0x3ff) * 10);
		pp_printf("offset : 	%d ps \r\n", ((delay >> 10)) * 10);
	}

    MU1->skew_mes_ctl = 0;
	// unsigned int res;
	// mu_stat = mu_measure_skew(MU1, master_ch, &res);

	// if (mu_stat == MU_OK) {
	// 	pp_printf("skew = %d ps\r\n", res * 10);
	// }
	// if (mu_stat == MU_ERR) {
	// 	pp_printf("can not measure skew\r\n");
	// }
}

int main(void) {
	uart_init(UART1, 19200);

	pp_printf("WR Calibrator \r\n");

	MU1->conf = (64 <<1);
	pp_printf("%d\r\n", MU1->conf);

	// test_chan(MU_CH_1);
	test_chan(MU_CH_1);
	MU1->conf = (64 <<1) | 1;
	while (1);
}
