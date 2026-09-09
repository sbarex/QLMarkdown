//
//  defl.c
//  QLMarkdown
//
//  Created by soreavis on 28/06/26.
//

#include "defl.h"

#include <stdint.h>

#include "../../cmark-gfm/src/parser.h"
#include "../../cmark-gfm/src/render.h"
#include "../../cmark-gfm/src/html.h"

// cmark-gfm has no native definition lists. This post-process extension
// rewrites the compact `term` / `: description` syntax (no blank line between
// the lines) into <dl>/<dt>/<dd>, moving the parsed inlines into the new nodes
// so markup in terms and descriptions is preserved.

typedef enum {
    DEFL_LIST = 1,
    DEFL_TERM,
    DEFL_DESCRIPTION,
} defl_kind;

// The list wrapper is a CMARK_NODE_CUSTOM_BLOCK; the term and description are
// paragraphs so their moved inline children (links, emphasis, …) sit in the
// inline container cmark's renderer expects. Each is tagged so html_render
// emits <dl>/<dt>/<dd> instead of the node's default markup.
static cmark_node *make_node(cmark_mem *mem, cmark_syntax_extension *ext, cmark_node_type type, defl_kind kind) {
    cmark_node *node = cmark_node_new_with_mem_and_ext(type, mem, ext);
    cmark_node_set_user_data(node, (void *)(intptr_t)kind);
    return node;
}

static int is_definition_list(cmark_syntax_extension *ext, cmark_node *node) {
    return node && node->extension == ext &&
           (defl_kind)(intptr_t)cmark_node_get_user_data(node) == DEFL_LIST;
}

// A description line is a text node whose content begins with the ':' marker.
static int starts_description(cmark_node *line) {
    if (!line || line->type != CMARK_NODE_TEXT) {
        return 0;
    }
    const char *text = cmark_node_get_literal(line);
    return text != NULL && text[0] == ':';
}

// Count the `: …` description lines in a paragraph, or 0 when it is not a
// definition list: it must have a non-empty term and every line after the
// first must be a description.
static int count_descriptions(cmark_node *para) {
    cmark_node *child = cmark_node_first_child(para);
    if (!child || child->type == CMARK_NODE_SOFTBREAK) {
        return 0;
    }
    int count = 0;
    for (; child; child = cmark_node_next(child)) {
        if (child->type != CMARK_NODE_SOFTBREAK) {
            continue;
        }
        if (!starts_description(cmark_node_next(child))) {
            return 0;
        }
        count++;
    }
    return count;
}

// Drop the ':' marker (and one optional following space) from a description's
// leading text node.
static void strip_marker(cmark_node *text) {
    const char *literal = cmark_node_get_literal(text);
    if (!literal || literal[0] != ':') {
        return;
    }
    const char *rest = literal + 1; // skip ':'
    if (*rest == ' ') {
        rest++;
    }
    // set_literal copies rest into a new buffer before freeing the old one, so
    // passing a pointer into the node's own literal is safe.
    cmark_node_set_literal(text, rest);
}

// Move inlines starting at *cursor into dest until a soft break (or the end),
// leaving *cursor on that soft break (or NULL).
static void move_line(cmark_node **cursor, cmark_node *dest) {
    cmark_node *node = *cursor;
    while (node && node->type != CMARK_NODE_SOFTBREAK) {
        cmark_node *next = cmark_node_next(node);
        cmark_node_unlink(node);
        cmark_node_append_child(dest, node);
        node = next;
    }
    *cursor = node;
}

static void convert_paragraph(cmark_syntax_extension *ext, cmark_mem *mem, cmark_node *para) {
    // Merge into the immediately preceding definition list, when there is one,
    // so consecutive term/description paragraphs form a single <dl>.
    cmark_node *prev = cmark_node_previous(para);
    cmark_node *list = is_definition_list(ext, prev) ? prev : NULL;
    if (!list) {
        list = make_node(mem, ext, CMARK_NODE_CUSTOM_BLOCK, DEFL_LIST);
        cmark_node_insert_before(para, list);
    }

    // Reuse `para` as the <dt>: it keeps the term inlines (everything before the
    // first soft break) and, by staying in the tree, keeps its content buffer
    // alive — that buffer backs the literal of every inline, including the ones
    // moved into the <dd> nodes below, so freeing it would dangle them.
    cmark_node *cursor = cmark_node_first_child(para);
    while (cursor && cursor->type != CMARK_NODE_SOFTBREAK) {
        cursor = cmark_node_next(cursor);
    }
    cmark_node_unlink(para);
    cmark_node_set_syntax_extension(para, ext);
    cmark_node_set_user_data(para, (void *)(intptr_t)DEFL_TERM);
    cmark_node_append_child(list, para);

    while (cursor) { // cursor is the soft break before a description line
        cmark_node *separator = cursor;
        cursor = cmark_node_next(cursor);
        cmark_node_unlink(separator);
        cmark_node_free(separator);

        if (cursor) {
            strip_marker(cursor);
        }
        cmark_node *description = make_node(mem, ext, CMARK_NODE_PARAGRAPH, DEFL_DESCRIPTION);
        move_line(&cursor, description);
        cmark_node_append_child(list, description);
    }
}

static void process_children(cmark_syntax_extension *ext, cmark_mem *mem, cmark_node *parent) {
    cmark_node *child = cmark_node_first_child(parent);
    while (child) {
        cmark_node *next = cmark_node_next(child); // capture before child may be unlinked
        if (child->type == CMARK_NODE_PARAGRAPH) {
            if (count_descriptions(child) > 0) {
                convert_paragraph(ext, mem, child);
            }
        } else if (child->type == CMARK_NODE_BLOCK_QUOTE) {
            process_children(ext, mem, child);
        }
        child = next;
    }
}

static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    cmark_consolidate_text_nodes(root);
    process_children(ext, parser->mem, root);
    return root;
}

static void html_render(cmark_syntax_extension *extension,
                        struct cmark_html_renderer *renderer,
                        cmark_node *node,
                        cmark_event_type ev_type,
                        int options) {
    cmark_strbuf *html = renderer->html;
    int entering = ev_type == CMARK_EVENT_ENTER;

    switch ((defl_kind)(intptr_t)cmark_node_get_user_data(node)) {
    case DEFL_LIST:
        cmark_html_render_cr(html);
        cmark_strbuf_puts(html, entering ? "<dl>\n" : "</dl>\n");
        break;
    case DEFL_TERM:
        cmark_strbuf_puts(html, entering ? "<dt>" : "</dt>\n");
        break;
    case DEFL_DESCRIPTION:
        cmark_strbuf_puts(html, entering ? "<dd>" : "</dd>\n");
        break;
    }
}

cmark_syntax_extension *create_definitionlist_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("definitionlist");

    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    cmark_syntax_extension_set_html_render_func(ext, html_render);

    return ext;
}
