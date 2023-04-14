#include <stdlib.h>
#include <ctype.h>
#include "b64.h"

#ifdef b64_USE_CUSTOM_MALLOC
extern void* b64_malloc(size_t);
#endif

#ifdef b64_USE_CUSTOM_REALLOC
extern void* b64_realloc(void*, size_t);
#endif

// The number of buffers we need
int bufc = 0;

char* b64_buf_malloc()
{
	char* buf = b64_malloc(B64_BUFFER_SIZE);
	bufc = 1;
	return buf;
}

char* b64_buf_realloc(unsigned char* ptr, size_t size)
{
	if (size > bufc * B64_BUFFER_SIZE)
	{
		while (size > bufc * B64_BUFFER_SIZE) bufc++;
		char* buf = b64_realloc(ptr, B64_BUFFER_SIZE * bufc);
		if (!buf) return NULL;
		return buf;
	}

	return ptr;
}
