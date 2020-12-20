#include "checkbox.h"
#include <parser.h>
#include <render.h>

cmark_node_type CMARK_NODE_CHECKBOX;

typedef struct {
    int checked;
    int location;
    int length;
} checkbox_data;

int cmark_node_get_checkbox_checked(cmark_node *node) {
    if (node->type != CMARK_NODE_CHECKBOX) {
        return -1;
    }
    return ((checkbox_data *)node->as.opaque)->checked;
}

int cmark_node_get_checkbox_location(cmark_node *node) {
    if (node->type != CMARK_NODE_CHECKBOX) {
        return -1;
    }
    return ((checkbox_data *)node->as.opaque)->location;
}

int cmark_node_get_checkbox_length(cmark_node *node) {
    if (node->type != CMARK_NODE_CHECKBOX) {
        return -1;
    }
    return ((checkbox_data *)node->as.opaque)->length;
}

static cmark_node *match(cmark_syntax_extension *self, cmark_parser *parser,
                         cmark_node *parent, unsigned char character,
                         cmark_inline_parser *inline_parser) {
    if (parent->parent == NULL
        || parent->parent->type != CMARK_NODE_ITEM
        || !(
             character == ' '
             || character == 'x'
             || character == 'X')
        ) {
        return NULL;
    }

    // must be the second character in a list item paragraph block
    int index = cmark_inline_parser_get_offset(inline_parser);
    if (index != 1) {
        return NULL;
    }

    cmark_chunk *chunk = cmark_inline_parser_get_chunk(inline_parser);
    size_t size = chunk->len;

    uint8_t *data = chunk->data;

    int len = 3;
    int leftBracket = index - 1;
    if (size - leftBracket < len
        || data[leftBracket] != '['
        || data[index + 1] != ']') {
        return NULL;
    }

    cmark_node *node = cmark_node_new_with_mem(CMARK_NODE_CHECKBOX, parser->mem);

    checkbox_data *checkbox;
    node->as.opaque = checkbox = parser->mem->calloc(1, sizeof(checkbox_data));
    checkbox->checked = character != ' ';
    // checkbox->location = parent->origin_offset - leftBracket;
    checkbox->length = len;

    cmark_inline_parser_set_offset(inline_parser, leftBracket + len);
    // undo the left bracket being a text node
    cmark_node_unput(parent, 1);
    cmark_node_set_syntax_extension(node, self);

    return node;
}

static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
    const int checked = cmark_node_get_checkbox_checked(node);
    if (checked < 0) {
        return;
    }
    if (ev_type != CMARK_EVENT_ENTER) {
        return;
    }

    cmark_strbuf *html = renderer->html;
    cmark_strbuf_puts(html, "<input type=\"checkbox\" ");
    if (checked == 1) {
        cmark_strbuf_puts(html, "checked ");
    }
    cmark_strbuf_puts(html, "/>");
}

static const char *get_type_string(cmark_syntax_extension *extension,
                                   cmark_node *node) {
    return node->type == CMARK_NODE_CHECKBOX ? "checkbox" : "<unknown>";
}

static int can_contain(cmark_syntax_extension *extension, cmark_node *node,
                       cmark_node_type child_type) {
    if (node->type != CMARK_NODE_CHECKBOX) {
        return false;
    }
    return CMARK_NODE_TYPE_INLINE_P(child_type);
}

static void opaque_free(cmark_syntax_extension *self, cmark_mem *mem, cmark_node *node) {
    if (node->type == CMARK_NODE_CHECKBOX) {
        mem->free(node->as.opaque);
    }
}

cmark_syntax_extension *create_checkbox_extension(void) {
    cmark_syntax_extension *self = cmark_syntax_extension_new("checkbox");
    cmark_llist *special_chars = NULL;

    cmark_syntax_extension_set_get_type_string_func(self, get_type_string);
    cmark_syntax_extension_set_can_contain_func(self, can_contain);
    cmark_syntax_extension_set_opaque_free_func(self, opaque_free);
    cmark_syntax_extension_set_html_render_func(self, html_render);

    CMARK_NODE_CHECKBOX = cmark_syntax_extension_add_node(1);

    cmark_syntax_extension_set_match_inline_func(self, match);

    cmark_mem *mem = cmark_get_default_mem_allocator();
    special_chars = cmark_llist_append(mem, special_chars, (void *)' ');
    special_chars = cmark_llist_append(mem, special_chars, (void *)'x');
    special_chars = cmark_llist_append(mem, special_chars, (void *)'X');
    cmark_syntax_extension_set_special_inline_chars(self, special_chars);

    return self;
}

