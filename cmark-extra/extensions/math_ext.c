//
//  math_ext.c
//  QLMarkdown
//
//  Created by Sbarex on 14/04/23.
//

#include "math_ext.h"

#include "../../cmark-gfm/src/parser.h"
#include "../../cmark-gfm/src/render.h"
#include "../../cmark-gfm/src/html.h"

typedef struct {
    int count;
} math_settings;

static math_settings *init_settings(void ) {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    math_settings *settings = mem->calloc(1, sizeof(math_settings));
    settings->count = 0;
    return settings;
}

static void math_settings_release(cmark_mem *mem, void *user_data)
{
    if (user_data) {
        math_settings *settings = user_data;
        settings->count = 0;
        
        cmark_mem *mem = cmark_get_default_mem_allocator();
        
        mem->free(user_data);
    }
}

static math_settings *cmark_syntax_extension_math_get_settings(cmark_syntax_extension *extension) {
    return (math_settings *)cmark_syntax_extension_get_private(extension);
}


int cmark_syntax_extension_math_get_rendered_count(cmark_syntax_extension *extension) {
    math_settings *settings = cmark_syntax_extension_math_get_settings(extension);
    if (settings) {
        return settings->count;
    } else {
        return 0;
    }
}

void cmark_syntax_extension_math_set_rendered_count(cmark_syntax_extension *extension, int value) {
    math_settings *settings = cmark_syntax_extension_math_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, math_settings_release);
    }
    settings->count = value;
}

void cmark_syntax_extension_math_increment_rendered_count(cmark_syntax_extension *extension, int delta) {
    math_settings *settings = cmark_syntax_extension_math_get_settings(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, math_settings_release);
    }
    settings->count += delta;
}

cmark_node_type CMARK_NODE_DOLLARS;

typedef struct {
    cmark_chunk     literal;
    bool            is_display_equation;
} dollars_data;

static void math_opaque_alloc(cmark_syntax_extension *ext, cmark_mem *mem, cmark_node *node) {
    if (node->type == CMARK_NODE_DOLLARS) {
        node->as.opaque = mem->calloc(1, sizeof(dollars_data));
    }
}


static void math_opaque_free(cmark_syntax_extension *ext, cmark_mem *mem, cmark_node *node) {
    if (node->type == CMARK_NODE_DOLLARS) {
        dollars_data* data = (dollars_data*) node->as.opaque;
        cmark_chunk_free(mem,&data->literal);
        mem->free(node->as.opaque);
    }
}

static cmark_node *match_inline_math(cmark_syntax_extension *ext, cmark_parser *parser,
                                     cmark_node *parent, unsigned char character,
                                     cmark_inline_parser *inline_parser) {
    
    cmark_node *res = NULL;
    int left_flanking, right_flanking, punct_before, punct_after, delims;
    char buffer[101];

    if (character != '$')
        return NULL;

    delims = cmark_inline_parser_scan_delimiters(
        inline_parser, sizeof(buffer) - 1, '$',
        &left_flanking,
        &right_flanking, &punct_before, &punct_after);

    memset(buffer, '$', delims);
    buffer[delims] = 0;

    res = cmark_node_new_with_mem(CMARK_NODE_TEXT, parser->mem);
    cmark_node_set_literal(res, buffer);
    res->start_line = res->end_line = cmark_inline_parser_get_line(inline_parser);
    res->start_column = cmark_inline_parser_get_column(inline_parser) - delims;
    
    if (punct_before) {
        right_flanking = false;
    }
    if (punct_after) {
        left_flanking = false;
    }
    int not_flanking = !(left_flanking || right_flanking);
    int can_open  = left_flanking  || not_flanking;
    int can_close = right_flanking || not_flanking;
    if (delims == 2 || delims == 1) {
        cmark_inline_parser_push_delimiter(inline_parser, character, can_open, can_close, res);
    }

    return res;
}

static delimiter *insert_math(cmark_syntax_extension *ext, cmark_parser *parser,
                              cmark_inline_parser *inline_parser, delimiter *opener,
                              delimiter *closer) {
    delimiter *delim, *tmp_delim;
    delimiter *res = closer->next;

    if (opener->inl_text->as.literal.len != closer->inl_text->as.literal.len)
        goto done;

    // setup dollars_data
    cmark_node *dollars_node = cmark_node_new_with_mem_and_ext(CMARK_NODE_DOLLARS,parser->mem,ext);
    if (!cmark_node_insert_before(opener->inl_text,dollars_node)) {
        cmark_node_free(dollars_node);
        goto done;
    }

    // original inline parser data
    cmark_chunk *chunk = cmark_inline_parser_get_chunk(inline_parser);
    uint8_t *data = chunk->data;

    dollars_data* dd = (dollars_data*)dollars_node->as.opaque;
    dd->is_display_equation = opener->inl_text->as.literal.len > 1;

    int len = closer->position 
            - opener->position
            + opener->inl_text->as.literal.len;

    dd->literal.len = len;
    dd->literal.data = (unsigned char *)parser->mem->calloc(len + 1, 1);
    dd->literal.alloc = 1;
    memcpy(dd->literal.data, data+opener->position - opener->inl_text->as.literal.len, len);
    dd->literal.data[len] = 0;
    cmark_node_set_syntax_extension(dollars_node, ext);

    dollars_node->start_line = opener->inl_text->start_line;
    dollars_node->end_line = closer->inl_text->end_line;
    dollars_node->start_column = opener->inl_text->start_column;
    dollars_node->end_column = closer->inl_text->start_column + closer->inl_text->as.literal.len - 1;

    // remove original and captured notes
    cmark_node *tmp, *next;
    tmp = cmark_node_next(opener->inl_text);
    while (tmp) {
        if (tmp == closer->inl_text) {
            break;
        }
        next = cmark_node_next(tmp);
        cmark_node_free(tmp);
        tmp = next; 
    }
    cmark_node_free(opener->inl_text);
    cmark_node_free(closer->inl_text);

done:
    delim = closer;
    while (delim != NULL && delim != opener) {
        tmp_delim = delim->previous;
        cmark_inline_parser_remove_delimiter(inline_parser, delim);
        delim = tmp_delim;
    }

    cmark_inline_parser_remove_delimiter(inline_parser, opener);

    return res;
}


static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    // printf("POSTPROCESS SYNTAX\n");
    
    cmark_iter *iter;
    cmark_event_type ev;
    cmark_node *node;

    // Initialize the rendered count.
    cmark_syntax_extension_math_set_rendered_count(ext, 0);

    cmark_consolidate_text_nodes(root);
    iter = cmark_iter_new(root);

    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        node = cmark_iter_get_node(iter);
        
        // cmark_node_type type;
        // type = node->type;
        
        if (ev == CMARK_EVENT_ENTER && node->type == CMARK_NODE_CODE_BLOCK) {
            if (strcmp((const char *)node->as.code.info.data, "math") == 0) {
                cmark_node_set_syntax_extension(node, ext);
            }
        }
    }

    cmark_iter_free(iter);
    
    return root;
}

static void html_render_opentag(const char* tag,
                                cmark_html_renderer *renderer,
                                cmark_node *node, int options) {
    cmark_strbuf_puts(renderer->html, "\n<");
    cmark_strbuf_puts(renderer->html, tag);
    cmark_html_render_sourcepos(node, renderer->html, options);
    cmark_strbuf_puts(renderer->html, " class='hl math'");
    if (options & CMARK_OPT_GITHUB_PRE_LANG) {
      cmark_strbuf_puts(renderer->html, " lang=\"math\">");
    } else {
      cmark_strbuf_puts(renderer->html, ">");
    }
}

static void html_render_math( const cmark_chunk* literal, cmark_html_renderer *renderer) {
    bufsize_t pos = 0;
    bufsize_t len = literal->len;
    unsigned char* data = literal->data;

    while(pos < len) {
        bufsize_t next = cmark_chunk_strchr((cmark_chunk*)literal,'<',pos);
        cmark_strbuf_put(renderer->html, data+pos, next-pos);
        if (next<len) {
            cmark_strbuf_puts(renderer->html, "&lt;" ); // disallow html markup
        }
        pos = next+1;
    }
}


static void html_render_closetag(const char* tag, cmark_html_renderer *renderer) {
    cmark_strbuf_puts(renderer->html, "</"  );
    cmark_strbuf_puts(renderer->html, tag   );
    cmark_strbuf_puts(renderer->html, ">\n" );
}


static void html_render_dollars(cmark_html_renderer *renderer,
                                cmark_node *node,
                                int options) {
    
    dollars_data* dollars = (dollars_data*) node->as.opaque;
    const char* tag = dollars->is_display_equation ? "div" : "span";
    
    html_render_opentag( tag, renderer, node, options );
    html_render_math(&dollars->literal,renderer);
    html_render_closetag( tag, renderer);
}


static void html_render_math_code_block(cmark_html_renderer *renderer,
                                        cmark_node *node,
                                        int options) {

    const char* tag = "div";
    html_render_opentag(tag, renderer, node, options );
    cmark_strbuf_puts(renderer->html, "$$");
    html_render_math(&node->as.code.literal,renderer);
    cmark_strbuf_puts(renderer->html, "$$");
    html_render_closetag(tag, renderer );
}


static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {

    if (ev_type == CMARK_EVENT_ENTER) {
        if (node->type == CMARK_NODE_CODE_BLOCK) {
            html_render_math_code_block(renderer,node,options);
        }
        else if (node->type == CMARK_NODE_DOLLARS) {
            html_render_dollars(renderer,node,options);
        }
        cmark_syntax_extension_math_increment_rendered_count(extension, 1);
    }
}

cmark_syntax_extension *create_math_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("math");
    
    math_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, math_settings_release);

    CMARK_NODE_DOLLARS = cmark_syntax_extension_add_node(1);
    
    cmark_mem *mem = cmark_get_default_mem_allocator();
    cmark_llist *special_chars = cmark_llist_append(mem, NULL, (void *)'$');
    cmark_syntax_extension_set_special_inline_chars(ext,special_chars);

    cmark_syntax_extension_set_match_inline_func(ext, match_inline_math);
    cmark_syntax_extension_set_inline_from_delim_func(ext, insert_math);
    cmark_syntax_extension_set_opaque_alloc_func(ext,math_opaque_alloc);
    cmark_syntax_extension_set_opaque_free_func(ext, math_opaque_free);

    // cmark_syntax_extension_set_match_block_func(ext, matches);
    // cmark_syntax_extension_set_get_type_string_func(ext, get_type_string);
    // cmark_syntax_extension_set_open_block_func(ext, open_tasklist_item);
    // cmark_syntax_extension_set_can_contain_func(ext, can_contain);
    // cmark_syntax_extension_set_commonmark_render_func(ext, commonmark_render);
    // cmark_syntax_extension_set_plaintext_render_func(ext, commonmark_render);
    cmark_syntax_extension_set_html_render_func(ext, html_render);
    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    // cmark_syntax_extension_set_xml_attr_func(ext, xml_attr);

    return ext;
}



