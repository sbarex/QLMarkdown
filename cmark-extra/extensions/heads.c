//
//  heads.c
//  QLMarkdown
//
//  Created by Sbarex on 27/12/20.
//

#include "heads.h"
#include "heads_utils.hpp"

#include <stdint.h>
#include <stdlib.h>

#include <unistd.h>
#include <string.h>

#include "../../cmark-gfm/src/parser.h"
#include "../../cmark-gfm/src/render.h"
#include "../../cmark-gfm/src/html.h"

#include <locale.h>

typedef struct {
    SlugCounter *slugs;
} heads_settings;


// MARK: -

static heads_settings *init_settings(void ) {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    heads_settings *settings = mem->calloc(1, sizeof(heads_settings));
    settings->slugs = slugcounter_create();
    
    return settings;
}

static heads_settings *cmark_syntax_extension_heads_get_settings(cmark_syntax_extension *extension) {
    return (heads_settings *)cmark_syntax_extension_get_private(extension);
}

static void heads_settings_release(cmark_mem *mem, void *user_data)
{
    if (user_data) {
        heads_settings *settings = user_data;
        cmark_mem *mem = cmark_get_default_mem_allocator();
        if (settings->slugs) {
            slugcounter_free(settings->slugs);
            mem->free(settings->slugs);
            settings->slugs = NULL;
        }
        mem->free(user_data);
    }
}

static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    cmark_iter *iter;
    cmark_event_type ev;
    cmark_node *node;

    cmark_consolidate_text_nodes(root);
    iter = cmark_iter_new(root);
        
    char *current_locale = setlocale(LC_ALL, NULL);
    if (setlocale(LC_ALL, "en_US.UTF-8") == NULL) {
        // cerr << "setlocale failed.\n";
    }
    
    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        node = cmark_iter_get_node(iter);
        
        cmark_node_type type;
        type = node->type;
        
        if (ev != CMARK_EVENT_ENTER || type != CMARK_NODE_HEADING) {
            continue;
        }
        
        cmark_node_set_syntax_extension(node, ext);
    }
    
    cmark_iter_free(iter);
    
    // Restore previous locale.
    setlocale(LC_ALL, current_locale);
    
    
    return root;
}

static void html_render(cmark_syntax_extension *extension,
             struct cmark_html_renderer *renderer,
             cmark_node *node,
             cmark_event_type ev_type,
                        int options) {
    
    
    char start_heading[] = "<h0";
    char end_heading[] = "</h0";
    
    cmark_strbuf *html = renderer->html;
    
    heads_settings *settings =cmark_syntax_extension_heads_get_settings(extension);
    
    if (ev_type == CMARK_EVENT_ENTER) {
        cmark_html_render_cr(html);
        start_heading[2] = (char)('0' + node->as.heading.level);
        cmark_strbuf_puts(html, start_heading);
        // cmark_html_render_sourcepos(node, html, options);
        char *s = slug_title((const char *)node->content.ptr);
        
        if (s != NULL) {
            char *anchor = slugcounter_unique(settings->slugs, s);
            free(s);
            if (anchor) {
                cmark_strbuf_puts(html, " id=\"");
                cmark_strbuf_puts(html, anchor);
                cmark_strbuf_puts(html, "\"");
                free(anchor);
            }
        }
        
        cmark_strbuf_putc(html, '>');
        
    } else {
        end_heading[3] = (char)('0' + node->as.heading.level);
        cmark_strbuf_puts(html, end_heading);
        cmark_strbuf_puts(html, ">\n");
    }
    
}

cmark_syntax_extension *create_heads_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("heads");
    
    heads_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, heads_settings_release);
    
    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    cmark_syntax_extension_set_html_render_func(ext, html_render);
    
    return ext;
}


void heads_reset_slut_counter(cmark_syntax_extension *extension) {
    heads_settings *settings =cmark_syntax_extension_heads_get_settings(extension);
    slugcounter_free(settings->slugs);
}
