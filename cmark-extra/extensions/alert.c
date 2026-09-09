//
//  alert.c
//  QLMarkdown
//
//  Created by soreavis on 28/06/26.
//
//  GitHub Alerts (a.k.a. admonitions): blockquotes whose first line is
//  `[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]` or `[!CAUTION]` are
//  rendered as styled callout boxes, matching GitHub's behaviour.
//

#include "alert.h"

#include <stdint.h>
#include <string.h>
#include <strings.h>

#include "../../cmark-gfm/src/parser.h"
#include "../../cmark-gfm/src/render.h"
#include "../../cmark-gfm/src/html.h"

static const char *alert_markers[5] = { "[!NOTE]", "[!TIP]", "[!IMPORTANT]", "[!WARNING]", "[!CAUTION]" };
static const char *alert_class[5]   = { "note", "tip", "important", "warning", "caution" };
static const char *alert_label[5]   = { "Note", "Tip", "Important", "Warning", "Caution" };

// Return the alert type index (0..4) when `literal` is exactly an alert marker
// (case-insensitive keyword, trailing spaces allowed), otherwise -1. GitHub
// requires the marker to be alone on the blockquote's first line.
static int alert_type_for(const char *literal) {
    if (literal == NULL) {
        return -1;
    }
    size_t len = strlen(literal);
    while (len > 0 && (literal[len - 1] == ' ' || literal[len - 1] == '\t')) {
        len--;
    }
    for (int i = 0; i < 5; i++) {
        size_t marker_len = strlen(alert_markers[i]);
        if (len == marker_len && strncasecmp(literal, alert_markers[i], marker_len) == 0) {
            return i;
        }
    }
    return -1;
}

// Remove the "[!TYPE]" marker text (and the line break that follows it) from
// the first paragraph of the block quote; drop the paragraph if it ends empty.
static void strip_marker(cmark_node *block_quote) {
    cmark_node *paragraph = cmark_node_first_child(block_quote);
    if (paragraph == NULL || cmark_node_get_type(paragraph) != CMARK_NODE_PARAGRAPH) {
        return;
    }
    cmark_node *marker = cmark_node_first_child(paragraph);
    if (marker == NULL || cmark_node_get_type(marker) != CMARK_NODE_TEXT) {
        return;
    }
    cmark_node_unlink(marker);
    cmark_node_free(marker);

    cmark_node *next = cmark_node_first_child(paragraph);
    if (next != NULL && (cmark_node_get_type(next) == CMARK_NODE_SOFTBREAK || cmark_node_get_type(next) == CMARK_NODE_LINEBREAK)) {
        cmark_node_unlink(next);
        cmark_node_free(next);
    }

    if (cmark_node_first_child(paragraph) == NULL) {
        cmark_node_unlink(paragraph);
        cmark_node_free(paragraph);
    }
}

static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    cmark_consolidate_text_nodes(root);

    cmark_mem *mem = cmark_get_default_mem_allocator();
    cmark_llist *matches = NULL;

    cmark_iter *iter = cmark_iter_new(root);
    cmark_event_type ev;
    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        if (ev != CMARK_EVENT_ENTER) {
            continue;
        }
        cmark_node *node = cmark_iter_get_node(iter);
        if (cmark_node_get_type(node) != CMARK_NODE_BLOCK_QUOTE) {
            continue;
        }
        cmark_node *paragraph = cmark_node_first_child(node);
        if (paragraph == NULL || cmark_node_get_type(paragraph) != CMARK_NODE_PARAGRAPH) {
            continue;
        }
        cmark_node *text = cmark_node_first_child(paragraph);
        if (text == NULL || cmark_node_get_type(text) != CMARK_NODE_TEXT) {
            continue;
        }
        int type = alert_type_for(cmark_node_get_literal(text));
        if (type < 0) {
            continue;
        }

        // Tag the node now (does not mutate the tree); strip the marker later.
        cmark_node_set_user_data(node, (void *)(intptr_t)(type + 1));
        cmark_node_set_syntax_extension(node, ext);
        matches = cmark_llist_append(mem, matches, node);
    }
    cmark_iter_free(iter);

    // Strip markers after iteration to avoid mutating the tree while walking it.
    for (cmark_llist *tmp = matches; tmp != NULL; tmp = tmp->next) {
        strip_marker((cmark_node *)tmp->data);
    }
    cmark_llist_free(mem, matches);

    return root;
}

static void html_render(cmark_syntax_extension *extension,
                        struct cmark_html_renderer *renderer,
                        cmark_node *node,
                        cmark_event_type ev_type,
                        int options) {
    intptr_t stored = (intptr_t)cmark_node_get_user_data(node);
    if (stored < 1 || stored > 5) {
        return;
    }
    int idx = (int)(stored - 1);
    cmark_strbuf *html = renderer->html;

    if (ev_type == CMARK_EVENT_ENTER) {
        cmark_html_render_cr(html);
        cmark_strbuf_puts(html, "<div class=\"markdown-alert markdown-alert-");
        cmark_strbuf_puts(html, alert_class[idx]);
        cmark_strbuf_puts(html, "\">\n");
        cmark_strbuf_puts(html, "<p class=\"markdown-alert-title\">");
        cmark_strbuf_puts(html, alert_label[idx]);
        cmark_strbuf_puts(html, "</p>\n");
    } else {
        cmark_strbuf_puts(html, "</div>\n");
        cmark_html_render_cr(html);
    }
}

cmark_syntax_extension *create_alert_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("alert");

    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    cmark_syntax_extension_set_html_render_func(ext, html_render);

    return ext;
}
