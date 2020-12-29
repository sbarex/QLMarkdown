//
//  syntaxhighlight.c
//  QLMarkdown
//
//  Created by Sbarex on 09/12/20.
//

#include "syntaxhighlight.h"
#include <parser.h>
#include <render.h>
#include <html.h>
#include "ext_scanners.h"
#include "wrapper_highlight.h"
#include "goutils.h"
#include <houdini.h>

// Local constants
// static const char *TYPE_STRING = "syntaxhighlight";

typedef struct {
    char *theme_name;
    char *background_color;
    char *font_family;
    float font_size;
    int line_numbers;
    int tab_spaces;
    int wrap_limit;
    guess_type guess_language;
    char *magic_file;
    /*! Number of rendered code. */
    int count;
} syntax_highlight_settings;

/*
static const char *get_type_string(cmark_syntax_extension *extension, cmark_node *node) {
  return TYPE_STRING;
}
*/

static syntax_highlight_settings *init_settings() {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    syntax_highlight_settings *settings = mem->calloc(1, sizeof(syntax_highlight_settings));
    settings->background_color = NULL;
    settings->theme_name = NULL;
    settings->font_family = NULL;
    settings->magic_file = NULL;
    settings->font_size = 0;
    settings->line_numbers = 0;
    settings->tab_spaces = 0;
    settings->wrap_limit = 0;
    settings->guess_language = no_guess;
    
    settings->count = 0;
    return settings;
}

static syntax_highlight_settings *cmark_syntax_extension_highlight_get_settings(cmark_syntax_extension *extension) {
    return (syntax_highlight_settings *)cmark_syntax_extension_get_private(extension);
}

static void syntax_highlight_settings_release(cmark_mem *mem, void *user_data)
{
    if (user_data) {
        syntax_highlight_settings *settings = user_data;
        cmark_mem *mem = cmark_get_default_mem_allocator();
        if (settings->theme_name) {
            mem->free(settings->theme_name);
            settings->theme_name = NULL;
        }
        if (settings->background_color) {
            mem->free(settings->background_color);
            settings->background_color = NULL;
        }
        if (settings->font_family) {
            mem->free(settings->font_family);
            settings->font_family = NULL;
        }
        if (settings->magic_file) {
            mem->free(settings->magic_file);
            settings->magic_file = NULL;
        }
        mem->free(user_data);
    }
}

const char *cmark_syntax_extension_highlight_get_background_color(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return (const char *)settings->background_color;
    } else {
        return NULL;
    }
}

void cmark_syntax_extension_highlight_set_background_color(cmark_syntax_extension *extension, const char *color) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    cmark_mem *mem = cmark_get_default_mem_allocator();
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    if (settings->background_color) {
        mem->free(settings->background_color);
    }
    if (color) {
        unsigned long len;
        len = strlen(color);
        settings->background_color = mem->calloc(len, sizeof(char));
        strcpy(settings->background_color, color);
    } else {
        settings->background_color = NULL;
    }
}



const char *cmark_syntax_extension_highlight_get_theme_name(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return (const char *)settings->theme_name;
    } else {
        return NULL;
    }
}

void cmark_syntax_extension_highlight_set_theme_name(cmark_syntax_extension *extension, const char *name) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    cmark_mem *mem = cmark_get_default_mem_allocator();
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    if (settings->theme_name) {
        mem->free(settings->theme_name);
    }
    if (name) {
        settings->theme_name = strdup(name);
    } else {
        settings->theme_name = NULL;
    }
}

const char *cmark_syntax_extension_highlight_get_font_family(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return settings->font_family;
    } else {
        return NULL;
    }
}
void cmark_syntax_extension_highlight_set_font_family(cmark_syntax_extension *extension, const char *font, float size) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    if (settings->font_family) {
        free(settings->font_family);
    }
    if (font) {
        settings->font_family = strdup(font);
    } else {
        settings->font_family = NULL;
    }
    if (size >= 0) {
        settings->font_size = size;
    }
}

float cmark_syntax_extension_highlight_get_font_size(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return settings->font_size;
    } else {
        return 0;
    }
}
void cmark_syntax_extension_highlight_set_font_size(cmark_syntax_extension *extension, float size) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    settings->font_size = size;
}

int cmark_syntax_extension_highlight_get_line_number(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return settings->line_numbers;
    } else {
        return 0;
    }
}
void cmark_syntax_extension_highlight_set_line_number(cmark_syntax_extension *extension, int state) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    settings->line_numbers = state;
}

int cmark_syntax_extension_highlight_get_tab_spaces(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return settings->tab_spaces;
    } else {
        return 0;
    }
}
void cmark_syntax_extension_highlight_set_tab_spaces(cmark_syntax_extension *extension, int spaces) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    settings->tab_spaces = spaces;
}

int cmark_syntax_extension_highlight_get_wrap_limit(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return settings->wrap_limit;
    } else {
        return 0;
    }
}
void cmark_syntax_extension_highlight_set_wrap_limit(cmark_syntax_extension *extension, int spaces) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    settings->wrap_limit = spaces;
}

//! Get if the undefined languag is guessed.
guess_type cmark_syntax_extension_highlight_get_guess_language(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return settings->guess_language;
    } else {
        return 0;
    }
}
//! Set if the undefined languag is guessed.
void cmark_syntax_extension_highlight_set_guess_language(cmark_syntax_extension *extension, guess_type state) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    settings->guess_language = state;
}


//! Get the path of the magic database.
const char *cmark_syntax_extension_highlight_get_magic_file(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return settings->magic_file;
    } else {
        return NULL;
    }
}
//! Set the path of the magic database.
void cmark_syntax_extension_highlight_set_magic_file(cmark_syntax_extension *extension, const char *file) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    if (settings->magic_file) {
        free(settings->magic_file);
    }
    if (file) {
        settings->magic_file = strdup(file);
    } else {
        settings->magic_file = NULL;
    }
}

int cmark_syntax_extension_highlight_get_rendered_count(cmark_syntax_extension *extension) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (settings) {
        return settings->count;
    } else {
        return 0;
    }
}

void cmark_syntax_extension_highlight_set_rendered_count(cmark_syntax_extension *extension, int value) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    settings->count = value;
}

void cmark_syntax_extension_highlight_increment_rendered_count(cmark_syntax_extension *extension, int delta) {
    syntax_highlight_settings *settings = cmark_syntax_extension_highlight_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, syntax_highlight_settings_release);
    }
    settings->count += delta;
}

static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
    cmark_html_render_cr(renderer->html);
    
    if (options & CMARK_OPT_GITHUB_PRE_LANG) {
      cmark_strbuf_puts(renderer->html, "<pre");
      cmark_html_render_sourcepos(node, renderer->html, options);
      cmark_strbuf_puts(renderer->html, " class='hl' lang=\"");
      houdini_escape_html0(renderer->html, node->as.code.info.data, node->as.code.info.len, 0);
      cmark_strbuf_puts(renderer->html, "\"><code>");
    } else {
      cmark_strbuf_puts(renderer->html, "<pre");
      cmark_html_render_sourcepos(node, renderer->html, options);
      cmark_strbuf_puts(renderer->html, " class='hl'><code class=\"language-");
      houdini_escape_html0(renderer->html, node->as.code.info.data, node->as.code.info.len, 0);
      cmark_strbuf_puts(renderer->html, "\">");
    }
    
    cmark_html_render_sourcepos(node, renderer->html, options);
    // cmark_strbuf_puts(renderer->html, "lang: ");
    // cmark_strbuf_put(renderer->html, node->as.code.info.data, node->as.code.info.len);
    
    char *language = NULL;
    if (strlen((const char *)node->as.code.info.data) == 0) {
        guess_type guess = cmark_syntax_extension_highlight_get_guess_language(extension);
        if (guess == fast_guess) {
            const char *magic_db = cmark_syntax_extension_highlight_get_magic_file(extension);
            language = magic_guess_language((const char *)node->as.code.literal.data, magic_db);
            if (language == NULL) {
                language = strdup("");
            }
        } else if (guess == accurate_guess) {
            initEnryEngine();
            
            GoSlice content;
            content.data = node->as.code.literal.data;
            content.len = node->as.code.literal.len;
            content.cap = node->as.code.literal.len;
            language = guessWithEnry(content);
        } else {
            language = strdup((const char *)node->as.code.info.data);
        }
    } else {
        language = strdup((const char *)node->as.code.info.data);
    }
    
    int exit_code = 0;
    char *formatted = highlight_format_string2((const char *)node->as.code.literal.data, (const char *)language, &exit_code, true);
    free(language);
    if (exit_code == EXIT_SUCCESS && formatted != NULL) {
        cmark_strbuf_puts(renderer->html, formatted);
    }
    // cmark_strbuf_put(renderer->html, node->as.code.literal.data, node->as.code.literal.len);
    free(formatted);
    
    cmark_strbuf_puts(renderer->html, "</code></pre>\n");
    
    cmark_syntax_extension_highlight_increment_rendered_count(extension, 1);
}

char *cmark_syntax_extension_get_style(cmark_syntax_extension *extension) {
    const char *theme = cmark_syntax_extension_highlight_get_theme_name(extension);
    if (highlight_set_current_theme(theme) == EXIT_FAILURE) {
        // Missing theme, but a theme is required to analyze the code.
        highlight_set_current_theme("acid");
    }
    
    const char *background = cmark_syntax_extension_highlight_get_background_color(extension);
    int exit_code = 0;
    return highlight_format_style2(&exit_code, background);
}

/*
static void postprocess_text(cmark_parser *parser, cmark_node *node, int offset, int depth) {
    printf("postprocess_text\n");
}
*/

static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    // printf("POSTPROCESS SYNTAX\n");
    
    cmark_iter *iter;
    cmark_event_type ev;
    cmark_node *node;
    bool in_code = false;


    // Initialize a new generator and clear previous settings.
    highlight_init_generator();
    
    // Initialize the rendered count.
    cmark_syntax_extension_highlight_set_rendered_count(ext, 0);

    const char *theme = cmark_syntax_extension_highlight_get_theme_name(ext);
    int line_numbers = cmark_syntax_extension_highlight_get_line_number(ext);
    highlight_set_print_line_numbers(line_numbers);
    
    int tab_spaces = cmark_syntax_extension_highlight_get_tab_spaces(ext);
    int wrap_limit = cmark_syntax_extension_highlight_get_wrap_limit(ext);
    highlight_set_formatting_mode(wrap_limit, tab_spaces);
    
    // Is required to set the theme for parsing the code.
    if (highlight_set_current_theme(theme) == EXIT_FAILURE) {
        // Missing theme, but a theme is required to analyze the code.
        highlight_set_current_theme("acid");
    }
    
    const char *font = cmark_syntax_extension_highlight_get_font_family(ext);
    float size = cmark_syntax_extension_highlight_get_font_size(ext);
    if (font && strcmp(font, "") != 0) {
        char buf[20];
        gcvt(size, 2, buf);
        highlight_set_current_font(font, size > 0 ? buf : "1rem"); // 1rem is rendered as 1rempt, so it is ignored.
    } else {
        highlight_set_current_font("-apple-system, BlinkMacSystemFont, sans-serif", "1rem");
    }
    
    cmark_consolidate_text_nodes(root);
    iter = cmark_iter_new(root);

    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        node = cmark_iter_get_node(iter);
        
        // cmark_node_type type;
        // type = node->type;
        
        if (ev == CMARK_EVENT_ENTER && node->type == CMARK_NODE_CODE_BLOCK) {
            cmark_node_set_syntax_extension(node, ext);
        }
        
        if (in_code) {
            if (ev == CMARK_EVENT_EXIT && node->type == CMARK_NODE_CODE_BLOCK) {
                in_code = false;
            }
            continue;
        }

        if (ev == CMARK_EVENT_ENTER && node->type == CMARK_NODE_CODE_BLOCK) {
            in_code = true;
            continue;
        }
        
        if (!in_code) {
            continue;
        }
        
        if (ev == CMARK_EVENT_ENTER && node->type == CMARK_NODE_TEXT) {
            // postprocess_text(parser, node, 0, /*depth*/0);
        }
    }

    cmark_iter_free(iter);
    
    return root;
}

cmark_syntax_extension *create_syntaxhighlight_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("syntaxhighlight");
    
    syntax_highlight_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, syntax_highlight_settings_release);

  // FIXME cmark_syntax_extension_set_match_block_func(ext, matches);
  // cmark_syntax_extension_set_get_type_string_func(ext, get_type_string);
  // FIXME cmark_syntax_extension_set_open_block_func(ext, open_tasklist_item);
  // FIXME cmark_syntax_extension_set_can_contain_func(ext, can_contain);
  // cmark_syntax_extension_set_commonmark_render_func(ext, commonmark_render);
  // cmark_syntax_extension_set_plaintext_render_func(ext, commonmark_render);
    cmark_syntax_extension_set_html_render_func(ext, html_render);
    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
  // cmark_syntax_extension_set_xml_attr_func(ext, xml_attr);

    return ext;
}

void cmark_syntax_highlight_init(const char *search_dir) {
    highlight_init(search_dir);
}

char *colorizeCode(const char *code, const char *lexer, const char *theme, bool export_fragment, bool print_line_numbers) {
    int exit_code = 0;
    
    if (highlight_set_current_theme(theme) == EXIT_FAILURE) {
        // Missing theme.
        highlight_set_current_theme("acid");
    }
    
    highlight_set_current_theme(theme);
    highlight_set_print_line_numbers(print_line_numbers ? 1 : 0);
    return highlight_format_string2(code, lexer, &exit_code, export_fragment);
    
    //return convertCodeToHTML((char *)code, lexer, theme);
}
