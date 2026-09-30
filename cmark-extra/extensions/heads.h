//
//  heads.h
//  QLMarkdown
//
//  Created by Sbarex on 27/12/20.
//

#ifndef heads_h
#define heads_h

#include "cmark-gfm-core-extensions.h"

cmark_syntax_extension *create_heads_extension(void);

void heads_reset_slut_counter(cmark_syntax_extension *extension);


#endif /* heads_h */
