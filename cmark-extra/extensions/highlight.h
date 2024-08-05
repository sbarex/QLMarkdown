//
//  highlight.h
//  QLMarkdown
//
//  Created by Sbarex on 04/08/24.
//

#ifndef highlight_h
#define highlight_h

#include <stdio.h>
#include "cmark-gfm-core-extensions.h"

cmark_syntax_extension *create_highlight_extension(void);

#endif /* highlight_h */
