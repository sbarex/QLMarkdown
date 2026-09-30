//
//  heads_utils.hpp
//  QLMarkdown
//
//  Created by Sbarex on 27/12/20.
//

#ifndef heads_utils_hpp
#define heads_utils_hpp

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SlugCounter SlugCounter;

SlugCounter *slugcounter_create(void);
void slugcounter_free(SlugCounter *c);
char *slugcounter_unique(SlugCounter *c, const char *base);

char *slug_title(const char *title);

#ifdef __cplusplus
}
#endif

#endif /* heads_utils_hpp */
