#include "mu.h"
#include "../../pp_printf/pp-printf.h"

#define STB_GEN_WAIT_DELAY 1000000

// void delay(unsigned int n)  {
// 	while (--n) asm("");
// }

int mu_run_freq_detection(MU_TypeDef *mu_base, char mux, unsigned int threshold) {

    mu_set_threshold(mu_base, threshold);

    //                     clk src     chan src   run
	mu_base->stb_gen_ctl = (1 << 2) | ((mux & 1) << 1) | 1;
    
    //TODO 
    int n = STB_GEN_WAIT_DELAY;
	while (--n) asm("");

	if (mu_base->stb_gen_ctl & STB_GEN_RDY) {
        return MU_OK;
	} else {
        return MU_ERR;
	}
}

void mu_set_threshold(MU_TypeDef *mu_base, unsigned int threshold) {
    mu_base->threshold = threshold;
    while (!mu_base->threshold);
}