
#include "dev/dev.h"
#include "pp_printf/pp-printf.h"

// __attribute__((used)) 

void delay(unsigned int n)  {
	while (--n) asm("");
}

int main(void) {
	GPIOA->oe = 0xffffffff;
	uart_init(UART1, 19200);

	pp_printf("WR Calibrator \r\n");
	pp_printf("running frequency measurement\r\n");

	MU1->stb_gen = 1;
	pp_printf("%x\r\n", MU1->stb_gen);
	while (! (MU1->stb_gen & STB_GEN_RDY)) {
		if (MU1->stb_gen & STB_GEN_ERR) {
			pp_printf("err\r\n");
			break;
		}
	}
	pp_printf("%x\r\n", MU1->stb_gen);

	while(1);
	// while (1) {
	// 	mu_run_freq_detection(MU1, MUX_DAC1, 0xff);
	// 	unsigned int stat, tmp;
	// 	while ((stat = mu_stb_gen_status(MU1)) == MU_RUN);
	// 	if (stat == MU_ERR) pp_printf("can't measure signal frequency\r\n");
	// 	else {
	// 		tmp = MU1->stb_gen;
	// 		tmp >>= 3;
	// 		pp_printf("period = %d\r\n", tmp);
	// 	}
	// 	delay(500000);
	// }
	return 0;
}
