//
//  math.h
//  QLMarkdown
//
//  Created by Sbarex on 14/04/23.
//

#ifndef math_ext_h
#define math_ext_h

#include "cmark-gfm-core-extensions.h"

cmark_syntax_extension *create_math_extension(void);
//! Return the number of rendered fragment.
int cmark_syntax_extension_math_get_rendered_count(cmark_syntax_extension *extension);
//! Set the number of rendered fragment.
void cmark_syntax_extension_math_set_rendered_count(cmark_syntax_extension *extension, int value);
//! Increment the number of rendered fragment.
void cmark_syntax_extension_math_increment_rendered_count(cmark_syntax_extension *extension, int delta);


#include <stdio.h>

#endif /* math_ext_h */
