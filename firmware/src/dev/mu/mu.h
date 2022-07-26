#ifndef _MU_H_
#define _MU_H_

#define STB_GEN_RDY (1<<0)
#define STB_GEN_RUN (1<<0)
#define STB_GEN_MUX (1<<1)
#define STB_CLK_SEL (1<<2)

#define THRESHOLD_DAC1_RDY (1<<0)
#define THRESHOLD_DAC2_RDY (1<<1)

#define MU_CH_1 0
#define MU_CH_2 1

#define MU_CLK_INT 0
#define MU_CLK_EXT 1

#define MUX_DAC1    (0<<1)
#define MUX_DAC2    (1<<1)

#define SKEW_CTL_RDY (1<<2)
#define SKEW_CTL_ERR (0x7<<3)



#define MU_OK   1
#define MU_ERR  2
#define MU_RUN  3

typedef struct {
    volatile unsigned int stb_gen_ctl;
    volatile unsigned int threshold;
    volatile unsigned int stb_gen_period;
    volatile unsigned int skew_mes_ctl;
} MU_TypeDef;

int mu_run_freq_detection(MU_TypeDef *mu_base, char ch, char clk_sel, unsigned int threshold);

void mu_set_threshold(MU_TypeDef *mu_base, unsigned int threshold);

int mu_measure_skew(MU_TypeDef *mu_base, char master_ch, unsigned int *res);
// {skew_mes_delay_code, skew_mes_ctl_err, skew_mes_ctl_rdy, skew_mes_ctl_master_ch_sel, skew_mes_ctl_run};

#endif