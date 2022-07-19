#ifndef _MU_H_
#define _MU_H_

#define STB_GEN_RDY (1<<0)
#define STB_GEN_RUN (1<<0)
#define STB_GEN_MUX (1<<1)
#define STB_CLK_SEL (1<<2)

#define THRESHOLD_DAC1_RDY (1<<0)
#define THRESHOLD_DAC2_RDY (1<<1)

#define MUX_DAC1    (0<<1)
#define MUX_DAC2    (1<<1)

#define MU_OK   1
#define MU_ERR  2
#define MU_RUN  3

typedef struct {
    volatile unsigned int stb_gen_ctl;
    volatile unsigned int threshold;
    volatile unsigned int stb_gen_period;
    volatile unsigned int skew_mes_ctl;
} MU_TypeDef;

int mu_run_freq_detection(MU_TypeDef *mu_base, char mux, unsigned int threshold);

void mu_set_threshold(MU_TypeDef *mu_base, unsigned int threshold);

#endif