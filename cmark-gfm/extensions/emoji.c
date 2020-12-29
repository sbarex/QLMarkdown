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

static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    cmark_iter *iter;
    cmark_event_type ev;
    cmark_node *node;

    cmark_consolidate_text_nodes(root);
    iter = cmark_iter_new(root);

    bool use_characters = cmark_syntax_extension_emoji_get_use_characters(ext);
    
    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        node = cmark_iter_get_node(iter);
        
        // cmark_node_type type;
        // type = node->type;
        
        if (ev == CMARK_EVENT_ENTER && node->type == CMARK_NODE_TEXT) {
            const char *t = cmark_node_get_literal(node);
            if (use_characters) {
                if (t) {
                    char *s = replaceEmoji2((char *)t, 1);
                    if (s) {
                        cmark_node_set_literal(node, s);
                        free(s);
                    }
                }
            } else if (containsEmoji2((char *)t) > 0) {
                cmark_mem *mem = cmark_get_default_mem_allocator();
                cmark_strbuf dest;
                cmark_strbuf_init(mem, &dest, 0);
                houdini_escape_html0(&dest, (const uint8_t *)t, (int)strlen(t), 0);
                
                char *s = replaceEmoji2((char *)dest.ptr, 0);
                if (s) {
                    cmark_node_set_type(node, CMARK_NODE_HTML_INLINE);
                    cmark_node_set_literal(node, s);
                
                    free(s);
                }
                cmark_strbuf_free(&dest);
                
                // cmark_node_set_syntax_extension(node, ext);
            }
        }
    }

    cmark_iter_free(iter);
    
    return root;
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

cmark_syntax_extension *create_emoji_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("emoji");
    
    emoji_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, release_settings);
    
  // FIXME cmark_syntax_extension_set_match_block_func(ext, matches);
  // cmark_syntax_extension_set_get_type_string_func(ext, get_type_string);
  // FIXME cmark_syntax_extension_set_open_block_func(ext, open_tasklist_item);
  // FIXME cmark_syntax_extension_set_can_contain_func(ext, can_contain);
  // cmark_syntax_extension_set_commonmark_render_func(ext, commonmark_render);
  // cmark_syntax_extension_set_plaintext_render_func(ext, commonmark_render);
    // cmark_syntax_extension_set_html_render_func(ext, html_render);
    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
  // cmark_syntax_extension_set_xml_attr_func(ext, xml_attr);

    return ext;
}
