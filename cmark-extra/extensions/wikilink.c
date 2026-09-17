//
//  wikilink.c
//  QLMarkdown
//
//  Created by soreavis on 30/06/26.
//
//  Wikilinks: `[[Page Name]]` and `[[Target|Display]]` are rewritten into styled
//  links (`<a class="wikilink" href="…">…</a>`), matching the syntax used by Obsidian
//  and similar tools. cmark-gfm reserves `[` for its own link parser, so this can't be
//  an inline-match extension — instead it post-processes the parsed tree and splits
//  text nodes, like cmark-gfm's own `autolink` extension.
//

#include "wikilink.h"

#include <string.h>

#include "../../cmark-gfm/src/parser.h"
#include "../../cmark-gfm/src/render.h"
#include "../../cmark-gfm/src/houdini.h"
#include "../../cmark-gfm/src/scanners.h"

// Trim leading/trailing spaces and tabs from [*start, *start + *len).
static void trim(const uint8_t **start, size_t *len) {
    while (*len > 0 && ((*start)[0] == ' ' || (*start)[0] == '\t')) {
        (*start)++;
        (*len)--;
    }
    while (*len > 0 && ((*start)[*len - 1] == ' ' || (*start)[*len - 1] == '\t')) {
        (*len)--;
    }
}

// A located `[[ … ]]` wikilink, as byte offsets into the text buffer.
typedef struct {
    size_t open;       // the opening `[[`
    size_t inner;      // the inner text
    size_t inner_len;  // length of the inner text (non-empty, free of `[`/`]`)
    size_t close_end;  // just past the closing `]]`
    bool found;
} wikilink_match;

// Locate the next wikilink in data[from..len). The inner text must be non-empty and free
// of `[`/`]`, so malformed or nested brackets are skipped rather than half-matched.
static wikilink_match find_wikilink(const uint8_t *data, size_t len, size_t from) {
    for (size_t i = from; i + 1 < len; i++) {
        if (data[i] != '[' || data[i + 1] != '[') {
            continue;
        }
        size_t s = i + 2;
        size_t j = s;
        while (j + 1 < len && !(data[j] == ']' && data[j + 1] == ']')) {
            if (data[j] == '[' || data[j] == ']') {
                break; // stray bracket: not a clean wikilink
            }
            j++;
        }
        if (j + 1 >= len || data[j] != ']' || data[j + 1] != ']' || j == s) {
            continue; // no closing `]]`, or empty `[[]]`
        }
        return (wikilink_match){ .open = i, .inner = s, .inner_len = j - s, .close_end = j + 2, .found = true };
    }
    return (wikilink_match){ .found = false };
}

// Build a CMARK_NODE_LINK whose url is `target` and whose single text child is
// `display`, tagged with this extension so html_render() emits the wikilink markup.
static cmark_node *make_wikilink(cmark_syntax_extension *ext, cmark_parser *parser,
                                 const uint8_t *target, size_t target_len,
                                 const uint8_t *display, size_t display_len) {
    cmark_node *link = cmark_node_new_with_mem(CMARK_NODE_LINK, parser->mem);

    cmark_strbuf url;
    cmark_strbuf_init(parser->mem, &url, (bufsize_t)target_len + 1);
    cmark_strbuf_put(&url, target, (bufsize_t)target_len);
    link->as.link.url = cmark_chunk_buf_detach(&url);

    cmark_node *text = cmark_node_new_with_mem(CMARK_NODE_TEXT, parser->mem);
    cmark_strbuf label;
    cmark_strbuf_init(parser->mem, &label, (bufsize_t)display_len + 1);
    cmark_strbuf_put(&label, display, (bufsize_t)display_len);
    text->as.literal = cmark_chunk_buf_detach(&label);
    cmark_node_append_child(link, text);

    cmark_node_set_syntax_extension(link, ext);
    return link;
}

// Split `text` on every wikilink it contains, inserting the link nodes inline.
// Modelled on cmark-gfm's autolink postprocess_text().
static void postprocess_text(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *text) {
    if (text->as.literal.len < 5 ||
        memchr(text->as.literal.data, '[', text->as.literal.len) == NULL) {
        return; // shortest wikilink is "[[x]]"; no '[' means nothing to do
    }

    cmark_chunk detached = text->as.literal;
    text->as.literal = cmark_chunk_dup(&detached, 0, detached.len);

    const uint8_t *data = detached.data;
    size_t len = detached.len;
    size_t start = 0;  // start of the segment still held by `text`
    size_t search = 0;

    while (true) {
        wikilink_match m = find_wikilink(data, len, search);
        if (!m.found) {
            break;
        }

        // Split the inner text on the first `|` into target / display, then trim both.
        const uint8_t *t = data + m.inner;
        size_t t_len = m.inner_len;
        const uint8_t *bar = memchr(t, '|', m.inner_len);
        const uint8_t *d = t;
        size_t d_len = m.inner_len;
        if (bar != NULL) {
            t_len = (size_t)(bar - t);
            d = bar + 1;
            d_len = m.inner_len - t_len - 1;
        }
        trim(&t, &t_len);
        trim(&d, &d_len);
        if (t_len == 0) {
            search = m.open + 1; // empty target: leave `[[` literal, keep scanning
            continue;
        }
        if (d_len == 0) { // `[[Target|]]` → display falls back to the target
            d = t;
            d_len = t_len;
        }

        cmark_node *link = make_wikilink(ext, parser, t, t_len, d, d_len);
        cmark_node_insert_after(text, link);

        cmark_node *post = cmark_node_new_with_mem(CMARK_NODE_TEXT, parser->mem);
        post->as.literal = cmark_chunk_dup(&detached, (bufsize_t)m.close_end, (bufsize_t)(len - m.close_end));
        cmark_node_insert_after(link, post);

        text->as.literal = cmark_chunk_dup(&detached, (bufsize_t)start, (bufsize_t)(m.open - start));
        cmark_chunk_to_cstr(parser->mem, &text->as.literal);

        text = post;
        start = m.close_end;
        search = m.close_end;
    }

    cmark_chunk_to_cstr(parser->mem, &text->as.literal);
    cmark_chunk_free(parser->mem, &detached);
}

static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    cmark_consolidate_text_nodes(root);

    cmark_iter *iter = cmark_iter_new(root);
    cmark_event_type ev;
    bool in_link = false;
    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        cmark_node *node = cmark_iter_get_node(iter);
        cmark_node_type type = cmark_node_get_type(node);
        if (in_link) {
            if (ev == CMARK_EVENT_EXIT && type == CMARK_NODE_LINK) {
                in_link = false;
            }
            continue;
        }
        if (ev == CMARK_EVENT_ENTER && type == CMARK_NODE_LINK) {
            in_link = true; // don't create links inside existing links
        } else if (ev == CMARK_EVENT_ENTER && type == CMARK_NODE_TEXT) {
            postprocess_text(ext, parser, node);
        }
    }
    cmark_iter_free(iter);

    return root;
}

static void html_render(cmark_syntax_extension *extension,
                        struct cmark_html_renderer *renderer,
                        cmark_node *node, cmark_event_type ev_type, int options) {
    cmark_strbuf *html = renderer->html;
    if (ev_type == CMARK_EVENT_ENTER) {
        cmark_strbuf_puts(html, "<a class=\"wikilink\" href=\"");
        if ((options & CMARK_OPT_UNSAFE) || !scan_dangerous_url(&node->as.link.url, 0)) {
            houdini_escape_href(html, node->as.link.url.data, node->as.link.url.len);
        }
        cmark_strbuf_puts(html, "\">");
    } else {
        cmark_strbuf_puts(html, "</a>");
    }
}

cmark_syntax_extension *create_wikilink_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("wikilink");

    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    cmark_syntax_extension_set_html_render_func(ext, html_render);

    return ext;
}
