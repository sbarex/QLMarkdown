//
//  emoji.c
//  QLMarkdown
//
//  Created by Sbarex on 12/12/20.
//

#include "emoji.h"
#include <parser.h>
#include <render.h>
#include <html.h>
#include "ext_scanners.h"
#include "emoji_utils.hpp"
#include <houdini.h>
#include <scanners.h>

const char *emoji_image_size = "16";

typedef struct {
    bool use_images;
} emoji_settings;

static emoji_settings *init_settings() {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    emoji_settings *settings = mem->calloc(1, sizeof(emoji_settings));
    settings->use_images = false;
    return settings;
}

static void release_settings(cmark_mem *mem, void *user_data)
{
    if (user_data) {
        // emoji_settings *settings = user_data;
        cmark_mem *mem = cmark_get_default_mem_allocator();
        mem->free(user_data);
    }
}

// You must free the result if result is non-NULL.
char *str_replace(char *orig, char *rep, char *with) {
    char *result; // the return string
    char *ins;    // the next insert point
    char *tmp;    // varies
    unsigned long len_rep;  // length of rep (the string to remove)
    unsigned long len_with; // length of with (the string to replace rep with)
    unsigned long len_front; // distance between rep and end of last rep
    int count;    // number of replacements

    // sanity checks and initialization
    if (!orig || !rep)
        return NULL;
    len_rep = strlen(rep);
    if (len_rep == 0)
        return NULL; // empty rep causes infinite loop during count
    if (!with)
        with = "";
    len_with = strlen(with);

    // count the number of replacements needed
    ins = orig;
    for (count = 0; (tmp = strstr(ins, rep)); ++count) {
        ins = tmp + len_rep;
    }

    tmp = result = malloc(strlen(orig) + (len_with - len_rep) * count + 1);

    if (!result)
        return NULL;

    // first time through the loop, all the variable are set correctly
    // from here on,
    //    tmp points to the end of the result string
    //    ins points to the next occurrence of rep in orig
    //    orig points to the remainder of orig after "end of rep"
    while (count--) {
        ins = strstr(orig, rep);
        len_front = ins - orig;
        tmp = strncpy(tmp, orig, len_front) + len_front;
        tmp = strcpy(tmp, with) + len_with;
        orig += len_front + len_rep; // move to next "end of rep"
    }
    strcpy(tmp, orig);
    return result;
}

static cmark_node *match(cmark_syntax_extension *self, cmark_parser *parser,
                         cmark_node *parent, unsigned char character,
                         cmark_inline_parser *inline_parser) {
    if (character != ':')
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
           && (!cmark_isspace(data[end]) && data[end] != ':')) {
        end++;
    }

    if (end == at) {
        return NULL;
    }
    
    if (data[end] != ':') {
        return NULL;
    }
    
    char *placeholder = parser->mem->calloc(end-start, sizeof(char));
    memcpy(placeholder, &data[start+1], end-start-1);
    
    cmark_node *node = NULL;

    char *url = get_emoji_url(placeholder);
    if (url) {
        bool use_characters = cmark_syntax_extension_emoji_get_use_characters(self);
        if (use_characters) {
            char *emoji = get_emoji(placeholder);
            if (emoji) {
                node = cmark_node_new_with_mem(CMARK_NODE_TEXT, parser->mem);
                
                cmark_node_set_literal(node, emoji);
                
                // cmark_strbuf_sets(&node->content, emoji);
                free(emoji);
            } else {
                goto exit_func;
            }
        } else {
            node = cmark_node_new_with_mem(CMARK_NODE_IMAGE, parser->mem);
            
            // cmark_strbuf_sets(&node->content, placeholder);
            
            cmark_node_set_url(node, url);
            cmark_node_set_title(node, placeholder);
            cmark_node_set_syntax_extension(node, self);
        }
        
        cmark_inline_parser_set_offset(inline_parser, start + (end - start) + 1);
    }
    
exit_func:
    
    free(url);
    parser->mem->free(placeholder);
    
    return node;
}

bool cmark_syntax_extension_emoji_get_use_characters(cmark_syntax_extension *extension) {
    emoji_settings *settings = (emoji_settings *)cmark_syntax_extension_get_private(extension);
    return settings->use_images ? false : true;
}

void cmark_syntax_extension_emoji_set_use_characters(cmark_syntax_extension *extension, bool use_characters) {
    emoji_settings *settings = (emoji_settings *)cmark_syntax_extension_get_private(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, release_settings);
    }
    settings->use_images = !use_characters;
}

void html_render(cmark_syntax_extension *extension,
            struct cmark_html_renderer *renderer,
            cmark_node *node,
            cmark_event_type ev_type,
            int options) {
    cmark_strbuf *html = renderer->html;
    if (ev_type == CMARK_EVENT_ENTER) {
        cmark_strbuf_puts(html, "<img src=\"");
        if ((options & CMARK_OPT_UNSAFE) || !(scan_dangerous_url(&node->as.link.url, 0))) {
            houdini_escape_href(html, node->as.link.url.data, node->as.link.url.len);
        }
        cmark_strbuf_puts(html, "\" width=\"");
        cmark_strbuf_puts(html, emoji_image_size);
        cmark_strbuf_puts(html, "\" class=\"emoji\" alt=\"");
        renderer->plain = node;
    } else {
        if (node->as.link.title.len) {
            cmark_strbuf_puts(html, "\" title=\"");
            houdini_escape_html0(html, node->as.link.title.data, node->as.link.title.len, 0);
        }

        cmark_strbuf_puts(html, "\" />");
    }
}

cmark_syntax_extension *create_emoji_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("emoji");
    
    emoji_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, release_settings);
    
  // FIXME cmark_syntax_extension_set_match_block_func(ext, matches);
    
    cmark_syntax_extension_set_html_render_func(ext, html_render);

    // cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    cmark_syntax_extension_set_match_inline_func(ext, match);

    return ext;
}
