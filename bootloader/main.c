#define F_CPU 	25000000L
#define BAUD 	19200L

// #define GPIO_BASE 0x02000000
// #define GPIO_OE *(unsigned int*)(GPIO_BASE + 0x8)
// #define GPIO_OUT *(unsigned int*)(GPIO_BASE + 0x4)

#define UART1_BASE 0x03000000 
#define UART1_SETUP *(unsigned int*)(UART1_BASE + 0x0)
#define UART1_FIFO *(unsigned int*)(UART1_BASE + 0x4)
#define UART1_RX_DATA *(unsigned int*)(UART1_BASE + 0x8)
#define UART1_TX_DATA *(unsigned int*)(UART1_BASE + 0xC)

char getchar_() {
	while (1) {
		if (UART1_FIFO & 1) return UART1_RX_DATA;
	}
}

void _putchar(char character) {
    while (!(UART1_FIFO & (1<<16))) {}
    UART1_TX_DATA = character & 0xff;
}

void write_uint(unsigned int n) {
	for (int i = 0 ; i < 4; i++) {
		_putchar((unsigned char)(n>>(i*8)));
	}
}

typedef enum {
	IDLE_STATE, LOAD_STATE
} b_state;

#define LOAD 	0x01
#define EXIT 	0x00
#define ESCAPE 	0x7e

void main(void) {
	unsigned int cur_addr;	
	unsigned int data = 0, b_cnt = 0;

	b_state state = IDLE_STATE;

	// TODO check bootmode

	//init uart
	UART1_SETUP = F_CPU / BAUD;
	char in;
	while (1) {
		in = getchar_();
		if (in == ESCAPE) {
			in = getchar_();
		} else {
			switch (in) {
				case LOAD:
					cur_addr = 0;
					for (int i = 0; i < 4; i++) { //get 4 bytes of address
					 	cur_addr <<= 8;
						cur_addr |= ((unsigned int)getchar_());
					}
					state = LOAD_STATE;
					continue;

				case EXIT:
					__asm__("li ra, 0x04000000; ret");
					while(1);

				default: //ignore
					break;
			}
		}

		switch (state) {
		case IDLE_STATE:
			break;

		case LOAD_STATE:
			data |= ((unsigned int)in) << ((b_cnt++)*8);

			if (b_cnt == 4) {
				*(unsigned int *)cur_addr = data;
				data = 0;
				b_cnt = 0;
				cur_addr += 4;
			}
			break;
		}
	}
}
