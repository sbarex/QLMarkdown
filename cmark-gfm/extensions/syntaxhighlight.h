//
//  syntaxhighlight.h
//  QLMardown
//
//  Created by Sbarex on 09/12/20.
//

#ifndef syntaxhighlight_h
#define syntaxhighlight_h

#include "cmark-gfm-core-extensions.h"

cmark_syntax_extension *create_syntaxhighlight_extension(void);

typedef struct {
    char* theme_name;
    char* background_color;
} syntax_highlight_settings;

static syntax_highlight_settings *cmark_syntax_extension_highlight_get_settings(cmark_syntax_extension *extension);

const char *cmark_syntax_extension_highlight_get_theme_name(cmark_syntax_extension *extension);
void cmark_syntax_extension_highlight_set_theme_name(cmark_syntax_extension *extension, const char *name);
const char *cmark_syntax_extension_highlight_get_background_color(cmark_syntax_extension *extension);
void cmark_syntax_extension_highlight_set_background_color(cmark_syntax_extension *extension, const char *color);

char *themeInfo(const char *name);
char *colorizeCode(const char *code, const char *lexer, const char *theme);

int importNewStyle(const char *name, const char *settings);

#endif /* syntaxhighlight_h */
