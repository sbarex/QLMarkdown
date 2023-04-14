#include "mention.h"
#include "../../cmark-gfm/src/parser.h"
#include "../../cmark-gfm/src/render.h"

cmark_node_type CMARK_NODE_MENTION;

const char *cmark_node_get_mention_login(cmark_node *node) {
    if (node->type != CMARK_NODE_MENTION) {
        return NULL;
    }
    return cmark_chunk_to_cstr(cmark_node_mem(node), (cmark_chunk *)node->as.opaque);
}

static cmark_node *match(cmark_syntax_extension *self, cmark_parser *parser,
                         cmark_node *parent, unsigned char character,
                         cmark_inline_parser *inline_parser) {
    if (character != '@')
        return NULL;

    cmark_chunk *chunk = cmark_inline_parser_get_chunk(inline_parser);
    uint8_t *data = chunk->data;
    size_t size = chunk->len;
    int start = cmark_inline_parser_get_offset(inline_parser);
    int at = start + 1;
    int end = at;

    if (start > 0 && !cmark_isspace(data[start-1])) {
        return NULL;
    }

    while (end < size
           && (cmark_isalnum(data[end]) || data[end] == '-')) {
        end++;
    }

    if (end == at) {
        return NULL;
    }

    cmark_node *node = cmark_node_new_with_mem(CMARK_NODE_MENTION, parser->mem);

    cmark_chunk *mention_chunk;
    node->as.opaque = mention_chunk = parser->mem->calloc(1, sizeof(cmark_chunk));
    mention_chunk->data = data + at;
    mention_chunk->len = end - at;

    cmark_inline_parser_set_offset(inline_parser, start + (end - start));
    cmark_node_set_syntax_extension(node, self);

    return node;
}

static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
    const char *login = cmark_node_get_mention_login(node);
    if (login == NULL) {
        return;
    }
    if (ev_type != CMARK_EVENT_ENTER) {
        return;
    }

    cmark_strbuf *html = renderer->html;
    cmark_strbuf_puts(html, "<a href=\"https://github.com/");
    cmark_strbuf_puts(html, login);
    cmark_strbuf_puts(html, "\">@");
    cmark_strbuf_puts(html, login);
    cmark_strbuf_puts(html, "</a>");
}

static const char *get_type_string(cmark_syntax_extension *extension,
                                   cmark_node *node) {
    return node->type == CMARK_NODE_MENTION ? "mention" : "<unknown>";
}

static int can_contain(cmark_syntax_extension *extension, cmark_node *node,
                       cmark_node_type child_type) {
    if (node->type != CMARK_NODE_MENTION)
        return false;

    return CMARK_NODE_TYPE_INLINE_P(child_type);
}

static void opaque_free(cmark_syntax_extension *self, cmark_mem *mem, cmark_node *node) {
    if (node->type == CMARK_NODE_MENTION) {
        mem->free(node->as.opaque);
    }
}

cmark_syntax_extension *create_mention_extension(void) {
    cmark_syntax_extension *self = cmark_syntax_extension_new("mention");
    cmark_llist *special_chars = NULL;

    cmark_syntax_extension_set_get_type_string_func(self, get_type_string);
    cmark_syntax_extension_set_can_contain_func(self, can_contain);
    cmark_syntax_extension_set_opaque_free_func(self, opaque_free);
    cmark_syntax_extension_set_html_render_func(self, html_render);

    CMARK_NODE_MENTION = cmark_syntax_extension_add_node(1);

    cmark_syntax_extension_set_match_inline_func(self, match);

    cmark_mem *mem = cmark_get_default_mem_allocator();
    special_chars = cmark_llist_append(mem, special_chars, (void *)'@');
    cmark_syntax_extension_set_special_inline_chars(self, special_chars);

    return self;
}

