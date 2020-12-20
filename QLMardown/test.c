//
//  test.c
//  QLMardown
//
//  Created by Sbarex on 10/12/20.
//

#include "test.h"
#include <stdint.h>
#include <stdbool.h>
#include <render.h>
#include <syntaxhighlight.h>
static void mio (cmark_syntax_extension *extension,
                                        struct cmark_html_renderer *renderer,
                                        cmark_node *node,
                                        cmark_event_type ev_type,
                                        int options)
{
    bool entering = (ev_type == CMARK_EVENT_ENTER);
    const unsigned char * lang;
    
    if (entering) {
      cmark_strbuf_puts(renderer->html, "<div>CIAO SIMONE");
    } else {
      cmark_strbuf_puts(renderer->html, "</div>");
    }
}


int processMyDoc(cmark_node *root) {
    cmark_event_type ev_type;
    cmark_iter *iter = cmark_iter_new(root);
    
    while ((ev_type = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        /*if (ev_type != CMARK_EVENT_ENTER) {
            continue;
        }*/
        cmark_node *cur = cmark_iter_get_node(iter);
        cmark_node_type type = cmark_node_get_type(cur);
        switch (type) {
            case CMARK_NODE_NONE:
                printf("CMARK_NODE_NONE");
                break;
            case CMARK_NODE_DOCUMENT:
                printf("CMARK_NODE_DOCUMENT");
                break;
            case CMARK_NODE_BLOCK_QUOTE:
                printf("CMARK_NODE_BLOCK_QUOTE");
                break;
            case CMARK_NODE_LIST:
                printf("CMARK_NODE_LIST");
                break;
            case CMARK_NODE_ITEM:
                printf("CMARK_NODE_ITEM");
                break;
            case CMARK_NODE_CODE_BLOCK:
                printf("CMARK_NODE_CODE_BLOCK");
                break;
            case CMARK_NODE_HTML_BLOCK:
                printf("CMARK_NODE_HTML_BLOCK");
                break;
            case CMARK_NODE_CUSTOM_BLOCK:
                printf("CMARK_NODE_CUSTOM_BLOCK");
                break;
            case CMARK_NODE_PARAGRAPH:
                printf("CMARK_NODE_PARAGRAPH");
                break;
            case CMARK_NODE_HEADING:
                printf("CMARK_NODE_HEADING");
                break;
            case CMARK_NODE_THEMATIC_BREAK:
                printf("CMARK_NODE_THEMATIC_BREAK");
                break;
            case CMARK_NODE_FOOTNOTE_DEFINITION:
                printf("CMARK_NODE_FOOTNOTE_DEFINITION");
                break;

            case CMARK_NODE_TEXT:
                printf("CMARK_NODE_TEXT");
                break;
            case CMARK_NODE_SOFTBREAK:
                printf("CMARK_NODE_SOFTBREAK");
                break;
            case CMARK_NODE_LINEBREAK:
                printf("CMARK_NODE_LINEBREAK");
                break;
            case CMARK_NODE_CODE:
                printf("CMARK_NODE_CODE");
                break;
            case CMARK_NODE_HTML_INLINE:
                printf("CMARK_NODE_HTML_INLINE");
                break;
            case CMARK_NODE_CUSTOM_INLINE:
                printf("CMARK_NODE_CUSTOM_INLINE");
                break;
            case CMARK_NODE_EMPH:
                printf("CMARK_NODE_EMPH");
                break;
            case CMARK_NODE_STRONG:
                printf("CMARK_NODE_STRONG");
                break;
            case CMARK_NODE_LINK:
                printf("CMARK_NODE_LINK");
                break;
            case CMARK_NODE_IMAGE:
                printf("CMARK_NODE_IMAGE");
                break;
            case CMARK_NODE_FOOTNOTE_REFERENCE:
                printf("CMARK_NODE_FOOTNOTE_REFERENCE");
                break;
        }
        printf(" #%d-%d\n", cmark_node_get_start_line(cur), cmark_node_get_end_line(cur));
        if (type == CMARK_NODE_CODE_BLOCK) {
            printf("%s\n", cmark_node_get_literal(cur));
            // cmark_node_set_literal(cur, "<b>ciao</b>");
            if (cmark_node_get_syntax_extension(cur) == NULL) {
                cmark_node_set_syntax_extension(cur, create_syntaxhighlight_extension());
            }
        }
        /*
        switch (ev_type) {
            case CMARK_EVENT_NONE:
                printf("CMARK_EVENT_NONE\n");
                break;
            case CMARK_EVENT_DONE:
                printf("CMARK_EVENT_DONE\n");
                break;
            case CMARK_EVENT_ENTER:
                printf("CMARK_EVENT_ENTER\n");
                break;
            case CMARK_EVENT_EXIT:
                printf("CMARK_EVENT_EXIT\n");
                break;
        }
         */
        // Do something with `cur` and `ev_type`
    }
    
    return 0;
}
