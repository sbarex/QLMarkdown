//
//  inlineimage.h
//  QLMardown
//
//  Created by Sbarex on 17/12/20.
//

#ifndef inlineimage_h
#define inlineimage_h

#include <stdio.h>

#include "cmark-gfm-core-extensions.h"

cmark_syntax_extension *create_inlineimage_extension(void);

char *cmark_syntax_extension_inlineimage_get_wd(cmark_syntax_extension *extension);
void cmark_syntax_extension_inlineimage_set_wd(cmark_syntax_extension *ext, const char *path);

#endif /* inlineimage_h */
