/*
 * Basic printf based on vprintf based on vsprintf
 *
 * Alessandro Rubini for CERN, 2011 -- public domain
 * (please note that the vsprintf is not public domain but GPL)
 */
#include <stdarg.h>
#include "pp-printf.h"

// in our case length buffer length will be 256
static char print_buf[256];

int pp_vprintf(const char *fmt, va_list args)
{
	int ret;

	ret = pp_vsprintf(print_buf, fmt, args);
	_puts(print_buf);
	return ret;
}

int pp_sprintf(char *s, const char *fmt, ...)
{
	va_list args;
	int ret;

	va_start(args, fmt);
	ret = pp_vsprintf(s, fmt, args);
	va_end(args);
	return ret;
}


int pp_printf(const char *fmt, ...)
{
	va_list args;
	int ret;

	va_start(args, fmt);
	ret = pp_vprintf(fmt, args);
	va_end(args);

	return ret;
}
