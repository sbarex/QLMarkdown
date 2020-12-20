//
//  syntaxhighlight.c
//  QLMardown
//
//  Created by Sbarex on 09/12/20.
//

#include "syntaxhighlight.h"
#include <parser.h>
#include <render.h>
#include <html.h>
#include "ext_scanners.h"
#include "htmlconverter.h"
#include <houdini.h>

// Local constants
static const char *TYPE_STRING = "syntaxhighlight";

static const char *get_type_string(cmark_syntax_extension *extension, cmark_node *node) {
  return TYPE_STRING;
}

static syntax_highlight_settings *init_settings() {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    syntax_highlight_settings *settings = mem->calloc(1, sizeof(syntax_highlight_settings));
    settings->background_color = NULL;
    settings->theme_name = NULL;
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
        unsigned long len;
        len = strlen(name);
        settings->theme_name = mem->calloc(len, sizeof(char));
        strcpy(settings->theme_name, name);
    } else {
        settings->theme_name = NULL;
    }
}

char *themeInfo(const char *name)  {
    return getStyleInfo((char *)name);
}



static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
    cmark_html_render_cr(renderer->html);
    
    const char *theme = cmark_syntax_extension_highlight_get_theme_name(extension);
    const char *background = cmark_syntax_extension_highlight_get_background_color(extension);
    char *style = getCSSStyle(node->as.code.info.data, theme, background);
    cmark_strbuf_puts(renderer->html, style);
    free(style);
    
    if (options & CMARK_OPT_GITHUB_PRE_LANG) {
      cmark_strbuf_puts(renderer->html, "<pre");
      cmark_html_render_sourcepos(node, renderer->html, options);
      cmark_strbuf_puts(renderer->html, " class='chroma' lang=\"");
      houdini_escape_html0(renderer->html, node->as.code.info.data, node->as.code.info.len, 0);
      cmark_strbuf_puts(renderer->html, "\"><code>");
    } else {
      cmark_strbuf_puts(renderer->html, "<pre");
      cmark_html_render_sourcepos(node, renderer->html, options);
      cmark_strbuf_puts(renderer->html, " class='chroma'><code class=\"language-");
      houdini_escape_html0(renderer->html, node->as.code.info.data, node->as.code.info.len, 0);
      cmark_strbuf_puts(renderer->html, "\">");
    }
    
    cmark_html_render_sourcepos(node, renderer->html, options);
    // cmark_strbuf_puts(renderer->html, "lang: ");
    // cmark_strbuf_put(renderer->html, node->as.code.info.data, node->as.code.info.len);
    
    char* formatted = convertCodeToHTML(node->as.code.literal.data, node->as.code.info.data, theme);
    
    cmark_strbuf_puts(renderer->html, formatted);
    // cmark_strbuf_put(renderer->html, node->as.code.literal.data, node->as.code.literal.len);
    free(formatted);
    
    cmark_strbuf_puts(renderer->html, "</code></pre>\n");
}

static void postprocess_text(cmark_parser *parser, cmark_node *node, int offset, int depth) {
    printf("postprocess_text\n");
    
}

static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    printf("POSTPROCESS SYNTAX\n");
    
    cmark_iter *iter;
    cmark_event_type ev;
    cmark_node *node;
    bool in_code = false;

    cmark_consolidate_text_nodes(root);
    iter = cmark_iter_new(root);

    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        node = cmark_iter_get_node(iter);
        
        cmark_node_type type;
        type = node->type;
        
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
        postprocess_text(parser, node, 0, /*depth*/0);
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

int importNewStyle(const char *name, const char *settings) {
    return (int)addStyle((char *)name, settings);
}

char *colorizeCode(const char *code, const char *lexer, const char *theme) {
    return convertCodeToHTML((char *)code, lexer, theme);
}
