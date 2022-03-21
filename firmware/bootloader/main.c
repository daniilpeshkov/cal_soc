#define F_CPU 	12000000L
#define BAUD 	9600

#define GPIO_BASE 0x02000000
#define GPIO_OE *(unsigned int*)(GPIO_BASE + 0x8)
#define GPIO_OUT *(unsigned int*)(GPIO_BASE + 0x4)

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

typedef enum {
	IDLE_STATE, LOAD_STATE
} b_state;

#define LOAD 	0x01
#define EXIT 	0x00
#define ESCAPE 	0x7e

void main(void) {
	unsigned int cur_addr;	
	b_state state = IDLE_STATE;

	// TODO check bootmode
	

	GPIO_OE = 0xffffffff;
	GPIO_OUT = 0xaa;

	//init uart
	UART1_SETUP = F_CPU / BAUD;
	char in;
	while (1) {
		in = getchar_();
		GPIO_OUT = 7;
		if (in == ESCAPE) {
			in = getchar_();
		} else {
			switch (in) {
				case LOAD:
					cur_addr = 0;
					GPIO_OUT = 1;
					for (int i = 0; i < 4; i++) { //get 4 bytes of address
						cur_addr |= ((unsigned int)getchar_() << (i*8));
					}
					GPIO_OUT = 2;
					state = LOAD_STATE;
					continue;

				case EXIT:
					GPIO_OUT = 0xff;
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
			*(unsigned char*)cur_addr = in;
			GPIO_OUT = in;
			cur_addr += 1;
			break;
		}
	}
}
