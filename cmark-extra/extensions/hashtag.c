//
//  hashtag.c
//  QLMarkdown
//
//  Created by soreavis on 26/09/26.
//
//  Hashtags: `#tag` and nested `#area/topic` are rendered as styled tags
//  (`<span class="hashtag">#tag</span>`), matching the tag syntax of Obsidian and
//  similar tools. A tag needs at least one character that is not a digit, so issue
//  references like `#123` stay plain text.
//

#include "hashtag.h"

#include "../../cmark-gfm/src/parser.h"
#include "../../cmark-gfm/src/render.h"
#include "../../cmark-gfm/src/houdini.h"
#include "../../cmark-gfm/src/utf8.h"

cmark_node_type CMARK_NODE_HASHTAG;

// Byte length of the tag character at data[pos], or 0 if the tag ends there.
// Like Obsidian: ASCII letters and digits, `_`, `-`, `/` (nested tags), and any
// other Unicode character that is not a space or punctuation (letters, emoji).
static int tag_char_len(const uint8_t *data, bufsize_t len, bufsize_t pos, bool *is_digit) {
    uint8_t c = data[pos];
    *is_digit = cmark_isdigit(c);
    if (c < 0x80) {
        return (cmark_isalnum(c) || c == '_' || c == '-' || c == '/') ? 1 : 0;
    }
    int32_t uc;
    int n = cmark_utf8proc_iterate(data + pos, len - pos, &uc);
    if (n <= 0 || cmark_utf8proc_is_space(uc) || cmark_utf8proc_is_punctuation(uc)) {
        return 0;
    }
    return n;
}

static cmark_node *match(cmark_syntax_extension *self, cmark_parser *parser,
                         cmark_node *parent, unsigned char character,
                         cmark_inline_parser *inline_parser) {
    if (character != '#') {
        return NULL;
    }

    cmark_chunk *chunk = cmark_inline_parser_get_chunk(inline_parser);
    const uint8_t *data = chunk->data;
    bufsize_t len = chunk->len;
    bufsize_t start = cmark_inline_parser_get_offset(inline_parser);

    if (start > 0 && !cmark_isspace(data[start - 1])) {
        return NULL; // `a#b`, URL fragments and `##` are not tags
    }
    if (cmark_inline_parser_in_bracket(inline_parser, false) ||
        cmark_inline_parser_in_bracket(inline_parser, true)) {
        return NULL; // like autolink: keeps image alt text and `[[wikilinks]]` intact
    }

    bufsize_t end = start + 1;
    bool has_non_digit = false;
    while (end < len) {
        bool is_digit;
        int n = tag_char_len(data, len, end, &is_digit);
        if (n == 0) {
            break;
        }
        has_non_digit |= !is_digit;
        end += n;
    }
    if (!has_non_digit) {
        return NULL; // empty, or all digits like `#123`
    }
    if (end + 2 < len && data[end] == ':' && data[end + 1] == '/' && data[end + 2] == '/') {
        return NULL; // `#https://x`: autolink would re-emit the scheme after the tag
    }

    cmark_node *node = cmark_node_new_with_mem(CMARK_NODE_HASHTAG, parser->mem);
    cmark_strbuf buf;
    cmark_strbuf_init(parser->mem, &buf, end - start);
    cmark_strbuf_put(&buf, data + start + 1, end - start - 1);
    cmark_chunk *tag = parser->mem->calloc(1, sizeof(cmark_chunk));
    *tag = cmark_chunk_buf_detach(&buf);
    node->as.opaque = tag;

    cmark_inline_parser_set_offset(inline_parser, end);
    cmark_node_set_syntax_extension(node, self);
    return node;
}

static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
    if (ev_type != CMARK_EVENT_ENTER) {
        return;
    }
    cmark_chunk *tag = (cmark_chunk *)node->as.opaque;
    cmark_strbuf *html = renderer->html;
    cmark_strbuf_puts(html, "<span class=\"hashtag\">#");
    houdini_escape_html0(html, tag->data, tag->len, 0);
    cmark_strbuf_puts(html, "</span>");
}

static void text_render(cmark_syntax_extension *extension,
                        cmark_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
    if (ev_type != CMARK_EVENT_ENTER) {
        return;
    }
    cmark_chunk *tag = (cmark_chunk *)node->as.opaque;
    renderer->out(renderer, node, "#", false, LITERAL);
    renderer->out(renderer, node, cmark_chunk_to_cstr(renderer->mem, tag), false, LITERAL);
}

static const char *get_type_string(cmark_syntax_extension *extension, cmark_node *node) {
    return node->type == CMARK_NODE_HASHTAG ? "hashtag" : "<unknown>";
}

static int can_contain(cmark_syntax_extension *extension, cmark_node *node,
                       cmark_node_type child_type) {
    return false;
}

static void opaque_free(cmark_syntax_extension *self, cmark_mem *mem, cmark_node *node) {
    if (node->type == CMARK_NODE_HASHTAG) {
        cmark_chunk_free(mem, (cmark_chunk *)node->as.opaque);
        mem->free(node->as.opaque);
    }
}

cmark_syntax_extension *create_hashtag_extension(void) {
    cmark_syntax_extension *self = cmark_syntax_extension_new("hashtag");

    cmark_syntax_extension_set_get_type_string_func(self, get_type_string);
    cmark_syntax_extension_set_can_contain_func(self, can_contain);
    cmark_syntax_extension_set_opaque_free_func(self, opaque_free);
    cmark_syntax_extension_set_html_render_func(self, html_render);
    cmark_syntax_extension_set_commonmark_render_func(self, text_render);
    cmark_syntax_extension_set_plaintext_render_func(self, text_render);

    CMARK_NODE_HASHTAG = cmark_syntax_extension_add_node(1);

    cmark_syntax_extension_set_match_inline_func(self, match);

    cmark_mem *mem = cmark_get_default_mem_allocator();
    cmark_llist *special_chars = cmark_llist_append(mem, NULL, (void *)'#');
    cmark_syntax_extension_set_special_inline_chars(self, special_chars);

    return self;
}
