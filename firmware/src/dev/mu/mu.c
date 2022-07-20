#include "mu.h"
#include "../../pp_printf/pp-printf.h"

#define STB_GEN_WAIT_DELAY 1000000

// void delay(unsigned int n)  {
// 	while (--n) asm("");
// }

int mu_run_freq_detection(MU_TypeDef *mu_base, char ch, char clk_sel, unsigned int threshold) {

    mu_set_threshold(mu_base, threshold);

    //                     clk src     chan src   run
	mu_base->stb_gen_ctl = ((clk_sel & 1) << 2) | ((ch & 1) << 1) | 1;

    //TODO maybe change 
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
    while (mu_base->threshold != 0x3) asm("");
}

int mu_measure_skew(MU_TypeDef *mu_base, char master_ch, unsigned int *res) {

    mu_base->skew_mes_ctl = ((master_ch & 1) << 1) | 1;

    while (!(mu_base->skew_mes_ctl & SKEW_CTL_RDY) & !(mu_base->skew_mes_ctl & SKEW_CTL_ERR));

    if (mu_base->skew_mes_ctl & SKEW_CTL_ERR) return MU_ERR;
    *res = mu_base->skew_mes_ctl >> 4;
    return MU_OK;
}