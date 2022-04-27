
#include "dev/dev.h"
#include "pp_printf/pp-printf.h"


unsigned int delay(unsigned int n) {
	while (n > 0) n--;
	return n;
}

int main(void) {
	GPIOA->oe = 0xffffffff;
	uart_init(UART1, 19200);

	pp_printf("WR Calibrator \r\n");
	pp_printf("running frequency measurement\r\n");
	mu_run_freq_detection(MU1, MUX_DAC1, 0xff);
	unsigned int stat;
	while ((stat = mu_stb_gen_status(MU1)) == MU_RUN);
	if (stat == MU_ERR) pp_printf("can't measure signal frequency\r\n");

	while(1) GPIOA->out = MU1->stb_gen;
	return 0;
}
