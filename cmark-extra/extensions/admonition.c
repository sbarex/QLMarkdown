//
//  admonition.c
//  QLMarkdown
//
//  Created by soreavis on 28/06/26.
//
//  MkDocs-style admonitions: a `!!! type [title]` line followed by its content
//  is rendered as a callout box, reusing the GitHub Alerts styling. cmark-gfm
//  has no native support, so the compact one-block form — the `!!!` line and
//  its softbreak-joined continuation in a single paragraph — is rewritten here
//  in a post-process pass. Types map onto the five alert styles.
//

#include "admonition.h"

#include <stdint.h>
#include <string.h>
#include <strings.h>
#include <ctype.h>

#include "../../cmark-gfm/src/parser.h"
#include "../../cmark-gfm/src/render.h"
#include "../../cmark-gfm/src/html.h"

static const char *alert_class[5] = { "note", "tip", "important", "warning", "caution" };

// MkDocs admonition types mapped onto the five alert styles; anything else
// falls back to "note" so every box stays themed.
static const struct { const char *name; int idx; } type_aliases[] = {
    { "note", 0 }, { "info", 0 }, { "question", 0 }, { "help", 0 },
    { "tip", 1 }, { "hint", 1 }, { "success", 1 },
    { "important", 2 }, { "example", 2 },
    { "warning", 3 }, { "attention", 3 },
    { "caution", 4 }, { "danger", 4 }, { "error", 4 }, { "bug", 4 }, { "failure", 4 },
};

static int resolve_type(const char *name, size_t len) {
    for (size_t i = 0; i < sizeof(type_aliases) / sizeof(type_aliases[0]); i++) {
        if (strlen(type_aliases[i].name) == len && strncasecmp(name, type_aliases[i].name, len) == 0) {
            return type_aliases[i].idx;
        }
    }
    return 0; // default: note
}

// Build the title: an explicit title (surrounding quotes stripped) when given,
// otherwise the capitalized type word. Caller frees.
static char *make_title(cmark_mem *mem, const char *rest, const char *type, size_t type_len) {
    const char *start = rest;
    const char *end = rest + strlen(rest);
    while (end > start && (end[-1] == ' ' || end[-1] == '\t')) {
        end--;
    }
    // Strip a matching pair of surrounding quotes — straight, or the smart
    // quotes that the CMARK_OPT_SMART option turns them into before we run.
    if (end - start >= 2 && ((start[0] == '"' && end[-1] == '"') || (start[0] == '\'' && end[-1] == '\''))) {
        start++;
        end--;
    } else if (end - start >= 6 && memcmp(start, "\xE2\x80\x9C", 3) == 0 && memcmp(end - 3, "\xE2\x80\x9D", 3) == 0) {
        start += 3; // “ … ”
        end -= 3;
    } else if (end - start >= 6 && memcmp(start, "\xE2\x80\x98", 3) == 0 && memcmp(end - 3, "\xE2\x80\x99", 3) == 0) {
        start += 3; // ‘ … ’
        end -= 3;
    }
    if (end > start) {
        size_t len = (size_t)(end - start);
        char *title = (char *)mem->calloc(len + 1, 1);
        memcpy(title, start, len);
        return title;
    }
    char *title = (char *)mem->calloc(type_len + 1, 1);
    memcpy(title, type, type_len);
    title[0] = (char)toupper((unsigned char)title[0]);
    for (size_t i = 1; i < type_len; i++) {
        title[i] = (char)tolower((unsigned char)title[i]);
    }
    return title;
}

// Parse a `!!! type [title]` opener from the paragraph's leading text. Returns
// the alert-style index (0..4) and allocates *title_out (caller frees), or -1
// when the text is not an admonition opener.
static int parse_opener(cmark_mem *mem, const char *literal, char **title_out) {
    *title_out = NULL;
    if (literal == NULL || strncmp(literal, "!!!", 3) != 0) {
        return -1;
    }
    const char *p = literal + 3;
    if (*p != ' ' && *p != '\t') {
        return -1; // require whitespace after `!!!` (rejects `!!!!`, `!!!x`)
    }
    while (*p == ' ' || *p == '\t') {
        p++;
    }
    const char *type = p;
    while (*p != '\0' && *p != ' ' && *p != '\t') {
        p++;
    }
    size_t type_len = (size_t)(p - type);
    if (type_len == 0) {
        return -1;
    }
    int idx = resolve_type(type, type_len);
    while (*p == ' ' || *p == '\t') {
        p++;
    }
    *title_out = make_title(mem, p, type, type_len);
    return idx;
}

// An admonition needs content after the opener line: a soft break followed by
// at least one more node. This also keeps the misleading empty box that the
// blank-line MkDocs form (content parsed as a separate code block) would
// otherwise produce, and avoids matching a lone `!!! word` paragraph.
static int has_body(cmark_node *para) {
    for (cmark_node *c = cmark_node_first_child(para); c != NULL; c = cmark_node_next(c)) {
        cmark_node_type type = cmark_node_get_type(c);
        if ((type == CMARK_NODE_SOFTBREAK || type == CMARK_NODE_LINEBREAK) && cmark_node_next(c) != NULL) {
            return 1;
        }
    }
    return 0;
}

static void convert(cmark_syntax_extension *ext, cmark_mem *mem, cmark_node *para, int idx, char *title) {
    cmark_node *box = cmark_node_new_with_mem_and_ext(CMARK_NODE_CUSTOM_BLOCK, mem, ext);
    cmark_node_set_user_data(box, (void *)(intptr_t)(idx + 1));
    cmark_node_insert_before(para, box);

    cmark_node *title_p = cmark_node_new_with_mem_and_ext(CMARK_NODE_PARAGRAPH, mem, ext);
    cmark_node *title_text = cmark_node_new_with_mem(CMARK_NODE_TEXT, mem);
    cmark_node_set_literal(title_text, title); // copies the string
    mem->free(title);
    cmark_node_append_child(title_p, title_text);
    cmark_node_append_child(box, title_p);

    // Drop the opener line: its inlines and the soft break that ends it.
    cmark_node *child = cmark_node_first_child(para);
    while (child != NULL) {
        cmark_node_type type = cmark_node_get_type(child);
        cmark_node *next = cmark_node_next(child);
        cmark_node_unlink(child);
        cmark_node_free(child);
        if (type == CMARK_NODE_SOFTBREAK || type == CMARK_NODE_LINEBREAK) {
            break;
        }
        child = next;
    }

    // Reuse `para` as the body so its content buffer stays alive to back the
    // moved inlines — freeing it would dangle them. `has_body` guarantees the
    // opener line left content behind.
    cmark_node_unlink(para);
    cmark_node_append_child(box, para);
}

static void process_children(cmark_syntax_extension *ext, cmark_mem *mem, cmark_node *parent) {
    cmark_node *child = cmark_node_first_child(parent);
    while (child != NULL) {
        cmark_node *next = cmark_node_next(child); // capture before child may be unlinked
        cmark_node_type type = cmark_node_get_type(child);
        if (type == CMARK_NODE_PARAGRAPH) {
            cmark_node *first = cmark_node_first_child(child);
            if (first != NULL && cmark_node_get_type(first) == CMARK_NODE_TEXT) {
                char *title = NULL;
                int idx = parse_opener(mem, cmark_node_get_literal(first), &title);
                if (idx >= 0 && has_body(child)) {
                    convert(ext, mem, child, idx, title);
                } else {
                    mem->free(title); // NULL-safe; nothing allocated when idx < 0
                }
            }
        } else if (type == CMARK_NODE_BLOCK_QUOTE) {
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

    if (cmark_node_get_type(node) == CMARK_NODE_CUSTOM_BLOCK) {
        intptr_t stored = (intptr_t)cmark_node_get_user_data(node);
        if (stored < 1 || stored > 5) {
            return;
        }
        if (entering) {
            cmark_html_render_cr(html);
            cmark_strbuf_puts(html, "<div class=\"markdown-alert markdown-alert-");
            cmark_strbuf_puts(html, alert_class[stored - 1]);
            cmark_strbuf_puts(html, "\">\n");
        } else {
            cmark_strbuf_puts(html, "</div>\n");
            cmark_html_render_cr(html);
        }
    } else { // tagged paragraph = the admonition title
        cmark_strbuf_puts(html, entering ? "<p class=\"markdown-alert-title\">" : "</p>\n");
    }
}

cmark_syntax_extension *create_admonition_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("admonition");

    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    cmark_syntax_extension_set_html_render_func(ext, html_render);

    return ext;
}
