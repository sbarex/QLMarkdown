//
//  inlineimage.h
//  QLMarkdown
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

/**
 * Get the base64 encoded data for a local image.
 * @param url image url
 * @return The encoded data with mime info to use for the src attribute of <img> tag. ** User must release the returned data.
 *         Return NULL if error occours.
 */
char *get_base64_image(const char *url);

#endif /* inlineimage_h */
