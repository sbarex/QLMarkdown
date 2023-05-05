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

static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
    cmark_html_render_cr(renderer->html);
    
    cmark_strbuf_puts(renderer->html, "<div");
    cmark_html_render_sourcepos(node, renderer->html, options);
    cmark_strbuf_puts(renderer->html, " class='hl math'");
    if (options & CMARK_OPT_GITHUB_PRE_LANG) {
      cmark_strbuf_puts(renderer->html, " lang=\"math\">");
    } else {
      cmark_strbuf_puts(renderer->html, ">");
    }
    
    cmark_strbuf_puts(renderer->html, "$$");
    cmark_strbuf_puts(renderer->html, (const char *)node->as.code.literal.data);
    cmark_strbuf_puts(renderer->html, "$$");
    
    cmark_strbuf_puts(renderer->html, "</div>\n");
    
    cmark_syntax_extension_math_increment_rendered_count(extension, 1);
}

cmark_syntax_extension *create_math_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("math");
    
    math_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, math_settings_release);

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



