b64.c
=====

Base64 encode/decode

## install

```sh
$ clib install littlstar/b64.c
```

## usage

```c
#include <b64/b64.h>
```

or

```c
#include <b64.h>
```

```c

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "b64.h"

int
main (void) {
  unsigned char *str = "brian the monkey and bradley the kinkajou are friends";
  char *enc = b64_encode(str, strlen(str));

  printf("%s\n", enc); // YnJpYW4gdGhlIG1vbmtleSBhbmQgYnJhZGxleSB0aGUga2lua2Fqb3UgYXJlIGZyaWVuZHM=

  char *dec = b64_decode(enc, strlen(enc));

  printf("%s\n", dec); // brian the monkey and bradley the kinkajou are friends
  free(enc);
  free(dec);
  return 0;
}
```

## api

Base64 index table

```c

static const char b64_table[] = {
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
  'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
  'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
  'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
  'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
  'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '0', '1', '2', '3',
  '4', '5', '6', '7', '8', '9', '+', '/'
};
```

Encode `unsigned char *` source with `size_t` size.
Returns a `char *` base64 encoded string

```c
char *
b64_encode (const unsigned char *, size_t);
```

Decode `char *` source with `size_t` size.
Returns a `unsigned char *` base64 decoded string

```c
unsigned char *
b64_decode (const char *, size_t);
```

## license

MIT
