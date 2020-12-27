//
//  inlineimage.c
//  QLMardown
//
//  Created by Sbarex on 17/12/20.
//

#include "inlineimage.h"
#include "MIMEType.h"

#include <stdint.h>
#include <stdlib.h>

#include <unistd.h>
#include <string.h>
#include "url.hpp"

#include <parser.h>
#include <render.h>

static char encoding_table[] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
                                'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
                                'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
                                'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
                                'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
                                'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
                                'w', 'x', 'y', 'z', '0', '1', '2', '3',
                                '4', '5', '6', '7', '8', '9', '+', '/'};
static int mod_table[] = {0, 2, 1};

char *base64_encode(const char *data,
                    size_t input_length,
                    size_t *output_length) {

    *output_length = 4 * ((input_length + 2) / 3);

    char *encoded_data = calloc(1, *output_length);
    if (encoded_data == NULL) return NULL;

    for (int i = 0, j = 0; i < input_length;) {
        uint32_t octet_a = i < input_length ? (unsigned char)data[i++] : 0;
        uint32_t octet_b = i < input_length ? (unsigned char)data[i++] : 0;
        uint32_t octet_c = i < input_length ? (unsigned char)data[i++] : 0;

        uint32_t triple = (octet_a << 0x10) + (octet_b << 0x08) + octet_c;

        encoded_data[j++] = encoding_table[(triple >> 3 * 6) & 0x3F];
        encoded_data[j++] = encoding_table[(triple >> 2 * 6) & 0x3F];
        encoded_data[j++] = encoding_table[(triple >> 1 * 6) & 0x3F];
        encoded_data[j++] = encoding_table[(triple >> 0 * 6) & 0x3F];
    }

    for (int i = 0; i < mod_table[input_length % 3]; i++) {
        encoded_data[*output_length - 1 - i] = '=';
    }

    return encoded_data;
}


typedef struct {
    char *path;
} inlineimage_settings;

static inlineimage_settings *init_settings() {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    inlineimage_settings *settings = mem->calloc(1, sizeof(inlineimage_settings));
    settings->path = NULL;
    return settings;
}

static void release_settings(cmark_mem *mem, void *user_data)
{
    if (user_data) {
        inlineimage_settings *settings = user_data;
        cmark_mem *mem = cmark_get_default_mem_allocator();
        if (settings->path) {
            mem->free(settings->path);
            settings->path = NULL;
        }
        mem->free(user_data);
    }
}

static bool startsWith(const char *pre, const char *str)
{
    size_t lenpre = strlen(pre),
           lenstr = strlen(str);
    return lenstr < lenpre ? false : memcmp(pre, str, lenpre) == 0;
}

static cmark_node *postprocess(cmark_syntax_extension *ext, cmark_parser *parser, cmark_node *root) {
    cmark_iter *iter;
    cmark_event_type ev;
    cmark_node *node;

    cmark_consolidate_text_nodes(root);
    iter = cmark_iter_new(root);
    
    char cwd[PATH_MAX];
    getcwd(cwd, sizeof(cwd));
    
    const char *basedir = cmark_syntax_extension_inlineimage_get_wd(ext);
    if (basedir) {
        // Change current dir to resolve local files.
        chdir(basedir);
    }
    
    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        node = cmark_iter_get_node(iter);
        
        // cmark_node_type type;
        // type = node->type;
        
        if (ev == CMARK_EVENT_ENTER && node->type == CMARK_NODE_IMAGE) {
            const char *url = (const char *)node->as.link.url.data;
            char *protocol = NULL, *host = NULL, *path = NULL, *query = NULL;
            const char *image_path;
            char *mime = NULL;
            parse_url(url, &protocol, &host, &path, &query);
            if (strcmp(protocol, "file") == 0) {
                // The url path is the local file path.
                image_path = path;
            } else if (strlen(host) == 0) {
                // No host, the url is a local file path.
                image_path = (const char *)url;
            } else {
                // Not a local file.
                goto continue_loop;
            }
            
            mime = get_mime(image_path, 2);
            
            if (!startsWith("image/", mime)) {
                fprintf(stderr, "%s (%s) is not an image!", image_path, mime);
                goto continue_loop;
            }
            if (access(image_path, F_OK) == 0) {
                char * buffer = 0;
                long length = 0;
                FILE * f = fopen((const char *)url, "rb");
                if (f) {
                    fseek (f, 0, SEEK_END);
                    length = ftell(f);
                    fseek (f, 0, SEEK_SET);
                    buffer = malloc(length);
                    if (buffer) {
                        fread(buffer, 1, length, f);
                    }
                    fclose(f);
                    
                    char *encoded = 0;
                    size_t encoded_length = 0;
                    encoded = base64_encode(buffer, length, &encoded_length);
                    
                    
                    char *prefix = (char *)calloc(strlen(mime)+strlen("data:;base64,"), sizeof(char));
                    sprintf(prefix, "data:%s;base64,", mime);
                    size_t prefix_length = sizeof(char)*strlen(prefix);
                    encoded = realloc(encoded, encoded_length + prefix_length);
                    memmove(encoded + prefix_length, encoded, encoded_length);
                    memcpy(encoded, prefix, prefix_length);
                    free(prefix);
                    
                    cmark_mem *mem = cmark_get_default_mem_allocator();
                    // Replace the original url with the encoded data.
                    cmark_chunk_set_cstr(mem, &node->as.link.url, encoded);
                    
                    free(buffer);
                    free(encoded);
                }
            }
            
        continue_loop:
            free(mime);
            
            free(protocol);
            free(path);
            free(host);
            free(query);
        }
    }
    
    chdir(cwd); // Restore previous current dir.

    cmark_iter_free(iter);
    
    return root;
}

void cmark_syntax_extension_inlineimage_set_wd(cmark_syntax_extension *ext, const char *path) {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(ext);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(ext, settings, release_settings);
    }
    if (settings->path) {
        mem->free(settings->path);
    }
    settings->path = mem->calloc(strlen(path)+1, sizeof(char));
    strcpy(settings->path, path);
}

char *cmark_syntax_extension_inlineimage_get_wd(cmark_syntax_extension *extension) {
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    return settings ? settings->path : NULL;
}

cmark_syntax_extension *create_inlineimage_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("inlineimage");
    
    inlineimage_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, release_settings);
    
    cmark_syntax_extension_set_postprocess_func(ext, postprocess);

    return ext;
}
