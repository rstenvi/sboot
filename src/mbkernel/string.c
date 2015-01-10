
#include "kernel.h"

size_t strlen(const char* str)  {
	if(str == NULL) return 0;
	size_t ret = 0;
	while(str[ret] != 0x00) ret++;
	return ret;
}

