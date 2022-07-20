
#include "dev/dev.h"
#include "pp_printf/pp-printf.h"

// __attribute__((used)) 

#define STB_GEN_WAIT_DELAY 1000000

void delay(unsigned int n)  {
	while (--n) asm("");
}


void test_chan (char ch) {
	int mu_stat = mu_run_freq_detection(MU1, ch, MU_CLK_EXT, 0xffff >> 2);

	if (mu_stat == MU_OK) {
		pp_printf("OK!\r\n");
		pp_printf("%d\r\n", MU1->stb_gen_period);
	} else {
		pp_printf("NOT OK!\r\n");
	}
}

int main(void) {
	uart_init(UART1, 19200);

	pp_printf("WR Calibrator \r\n");

	char master_ch = MU_CH_2;
	int mu_stat = mu_run_freq_detection(MU1, master_ch, MU_CLK_EXT, 0xffff >> 2);

	if (mu_stat != MU_OK) {
		pp_printf("can not detect signal from master\r\n");
		while (1);
	} else {
		pp_printf("stb ready\r\n");
	}

	unsigned int res;
	mu_stat = mu_measure_skew(MU1, master_ch, &res);

	if (mu_stat == MU_OK) {
		pp_printf("skew = %d ps\r\n", res * 10);
	}
	if (mu_stat == MU_ERR) {
		pp_printf("can not measure skew\r\n");
	}
	
	while (1);
}
