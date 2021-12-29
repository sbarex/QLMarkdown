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

#include <parser.h>
#include <render.h>
#include <html.h>

#include <locale.h>

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
    
    if (ev_type == CMARK_EVENT_ENTER) {
        cmark_html_render_cr(html);
        start_heading[2] = (char)('0' + node->as.heading.level);
        cmark_strbuf_puts(html, start_heading);
        // cmark_html_render_sourcepos(node, html, options);
        char *s = process_title((const char *)node->content.ptr);
        if (s != NULL) {
            cmark_strbuf_puts(html, " id=\"");
            cmark_strbuf_puts(html, s);
            cmark_strbuf_puts(html, "\"");
            free(s);
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
    
    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    cmark_syntax_extension_set_html_render_func(ext, html_render);
    
    return ext;
}
