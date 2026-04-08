//
//  syntaxhighlight.h
//  QLMarkdown
//
//  Created by Sbarex on 09/12/20.
//

#ifndef syntaxhighlight_h
#define syntaxhighlight_h

#include "cmark-gfm-core-extensions.h"

cmark_syntax_extension *create_syntaxhighlight_extension(void);

//! Initialize the search dir for highlight support files.
void cmark_syntax_highlight_init(const char *search_dir);

//! Get the theme name/full path for the extension.
const char *cmark_syntax_extension_highlight_get_theme_name(cmark_syntax_extension *extension);
//! Set the theme name/full path for the extension.
void cmark_syntax_extension_highlight_set_theme_name(cmark_syntax_extension *extension, const char *name);

//! Get the font family.
const char *cmark_syntax_extension_highlight_get_font_family(cmark_syntax_extension *extension);
//! Set the font family.
//! @param extension Extension reference.
//! @param font Family/Name of the font. Pass a empty value to use the Apple system font.
//! @param size Size for the font. -1 to not change previous value. 0 use standard size.
void cmark_syntax_extension_highlight_set_font_family(cmark_syntax_extension *extension, const char *font, float size);

//! Get the font size.
float cmark_syntax_extension_highlight_get_font_size(cmark_syntax_extension *extension);
//! Set the font size.
void cmark_syntax_extension_highlight_set_font_size(cmark_syntax_extension *extension, float size);

//! Get if the line numbers are shows.
int cmark_syntax_extension_highlight_get_line_number(cmark_syntax_extension *extension);
//! Set if the line numbers are shows.
void cmark_syntax_extension_highlight_set_line_number(cmark_syntax_extension *extension, int state);

//! Get the number of spaces for a tab.
int cmark_syntax_extension_highlight_get_tab_spaces(cmark_syntax_extension *extension);
//! Set the number of spaces for a tab. Set to zero to disable the tab substitution.
void cmark_syntax_extension_highlight_set_tab_spaces(cmark_syntax_extension *extension, int spaces);

//! Get the number of character before line wrap.
int cmark_syntax_extension_highlight_get_wrap_limit(cmark_syntax_extension *extension);
//! Set the number of character before line wrap.
void cmark_syntax_extension_highlight_set_wrap_limit(cmark_syntax_extension *extension, int spaces);


const char *cmark_syntax_extension_highlight_get_background_color(cmark_syntax_extension *extension);
void cmark_syntax_extension_highlight_set_background_color(cmark_syntax_extension *extension, const char *color);

//! Return the number of rendered fragment.
int cmark_syntax_extension_highlight_get_rendered_count(cmark_syntax_extension *extension);
//! Set the number of rendered fragment.
void cmark_syntax_extension_highlight_set_rendered_count(cmark_syntax_extension *extension, int value);
//! Increment the number of rendered fragment.
void cmark_syntax_extension_highlight_increment_rendered_count(cmark_syntax_extension *extension, int delta);

//! Return the css style for the theme (without the <style> tag).
//! **Remember to release the returned pointer.**
char *cmark_syntax_extension_get_style(cmark_syntax_extension *extension);

char *colorizeCode(const char *code, const char *lexer, const char *theme, bool export_fragment, bool print_line_numbers);

//! Add an item to the list of languages ​​to ignore in the highlighting process.
void cmark_syntax_extension_highlight_add_skipped_languages(cmark_syntax_extension *extension, const char *language);

//! Remove an item from the list of languages ​​to ignore in the highlighting process.
void cmark_syntax_extension_highlight_remove_skipped_languages(cmark_syntax_extension *extension, const char *language);

//! Clea the list of languages ​​to ignore in the highlighting process.
void cmark_syntax_extension_highlight_clear_skipped_languages(cmark_syntax_extension *extension, const char *language);


#endif /* syntaxhighlight_h */
