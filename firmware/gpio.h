#ifndef _GPIO_H_
#define _GPIO_H_

typedef struct {
    volatile unsigned int in;
    volatile unsigned int out;
    volatile unsigned int oe;
    volatile unsigned int inte;
    volatile unsigned int ptrig;
    volatile unsigned int aux;
    volatile unsigned int ctrl;
    volatile unsigned int ints;
    volatile unsigned int eclk;
    volatile unsigned int nec;
} GPIO_TypeDef;

#endif