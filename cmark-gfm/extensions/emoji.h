//
//  emoji.h
//  QLMardown
//
//  Created by Sbarex on 12/12/20.
//

#ifndef emoji_h
#define emoji_h

#include <stdio.h>
#include "cmark-gfm-core-extensions.h"

cmark_syntax_extension *create_emoji_extension(void);

bool cmark_syntax_extension_emoji_get_use_characters(cmark_syntax_extension *extension);
void cmark_syntax_extension_emoji_set_use_characters(cmark_syntax_extension *extension, bool use_characters);

#endif /* emoji_h */
