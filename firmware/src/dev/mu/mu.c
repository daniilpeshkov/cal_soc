#include "mu.h"

void mu_run_freq_detection(MU_TypeDef *mu_base, char mux, unsigned int threshold) {
    mu_base->threshold = threshold;
    while (mu_base->threshold != (THRESHOLD_DAC1_RDY | THRESHOLD_DAC2_RDY)); //wait for setting threshold;
    mu_base->stb_gen = mux | STB_GEN_RUN;
}

int mu_stb_gen_status(MU_TypeDef *mu_base) {
   unsigned int tmp = mu_base->stb_gen;
   if (tmp & STB_GEN_RDY) {
       if (tmp & STB_GEN_ERR) return MU_ERR;
       return MU_OK;
   } 
   return MU_RUN;
}