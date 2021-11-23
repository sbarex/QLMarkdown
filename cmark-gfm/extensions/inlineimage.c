//
//  inlineimage.c
//  QLMarkdown
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

#include <errno.h>

#include "b64.h"

typedef struct {
    char *path;
    MimeCheck *magic_callback;
    void *magic_context;
    int raw_images;
} inlineimage_settings;

static inlineimage_settings *init_settings() {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    inlineimage_settings *settings = mem->calloc(1, sizeof(inlineimage_settings));
    settings->path = NULL;
    settings->magic_callback = NULL;
    settings->magic_context = NULL;
    settings->raw_images = 0;
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
        settings->magic_callback = NULL;
        settings->magic_context = NULL;
        settings->raw_images = 0;
        mem->free(user_data);
    }
}

static bool startsWith(const char *pre, const char *str)
{
    if (pre == NULL || str == NULL) { // Saninty check.
        return 0;
    }
    
    size_t lenpre = strlen(pre),
           lenstr = strlen(str);
    return lenstr < lenpre ? false : memcmp(pre, str, lenpre) == 0;
}

char *get_base64_image(const char *url, MimeCheck *mime_callback, void *mime_context) {
    char *protocol = NULL, *host = NULL, *path = NULL, *query = NULL;
    const char *image_path;
    char *mime = NULL;
    char *encoded = NULL;
    
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
    
    if (access(image_path, F_OK) == 0) {
        if (mime_callback != NULL) {
            mime = mime_callback(image_path, mime_context);
        } else {
            mime = get_mime(image_path, 2);
        }
        if (!mime || !startsWith("image/", mime)) {
            fprintf(stderr, "%s (%s) is not an image!", image_path, mime);
            goto continue_loop;
        }
        
        char * buffer = 0;
        long length = 0;
        FILE * f = fopen((const char *)image_path, "rb");
        if (f) {
            fseek (f, 0, SEEK_END);
            length = ftell(f);
            fseek (f, 0, SEEK_SET);
            buffer = malloc(length);
            if (buffer) {
                fread(buffer, 1, length, f);
            }
            fclose(f);
            
            char *data = b64_encode((const unsigned char *)buffer, length);
            size_t encoded_length = strlen(data);
            
            encoded = (char *)calloc(strlen(mime) + strlen("data:;base64,") + encoded_length + 1, sizeof(char));
            sprintf(encoded, "data:%s;base64,%s", mime, data);
            
            free(data);
            free(buffer);
        } else {
            fprintf(stderr, "Error to get magic for file %s: #%d, %s\n", image_path, errno, strerror(errno));
        }
    } else {
        fprintf(stderr, "Unable to open file %s: #%d, %s\n", image_path, errno, strerror(errno));
    }
    
continue_loop:
    free(mime);
    
    free(protocol);
    free(path);
    free(host);
    free(query);
    
    return encoded;
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
            char *encoded = NULL;
            MimeCheck *mime_callback = cmark_syntax_extension_inlineimage_get_mime_callback(ext);
            void *mime_context = cmark_syntax_extension_inlineimage_get_mime_context(ext);
            encoded = get_base64_image(url, mime_callback, mime_context);
            if (encoded != NULL) {
                cmark_mem *mem = cmark_get_default_mem_allocator();
                // Replace the original url with the encoded data.
                cmark_chunk_set_cstr(mem, &node->as.link.url, encoded);
                free(encoded);
            }
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

int cmark_syntax_extension_inlineimage_get_raw_images_count(cmark_syntax_extension *ext) {
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(ext);
    if (!settings) {
        return 0;
    }
    return settings->raw_images;
}

void cmark_syntax_extension_inlineimage_set_raw_images_count(cmark_syntax_extension *ext, int value) {
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(ext);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(ext, settings, release_settings);
    }
    settings->raw_images = value;
}

void cmark_syntax_extension_inlineimage_increment_raw_images_count(cmark_syntax_extension *ext, int delta) {
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(ext);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(ext, settings, release_settings);
    }
    settings->raw_images += delta;
}

MimeCheck *cmark_syntax_extension_inlineimage_get_mime_callback(cmark_syntax_extension *extension)
{
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (settings) {
        return settings->magic_callback;
    } else {
        return NULL;
    }
}
void *cmark_syntax_extension_inlineimage_get_mime_context(cmark_syntax_extension *extension)
{
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (settings) {
        return settings->magic_context;
    } else {
        return NULL;
    }
}

void cmark_syntax_extension_inlineimage_set_mime_callback(cmark_syntax_extension *extension, MimeCheck *callback, void *context)
{
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, release_settings);
    }
    settings->magic_callback = callback;
    settings->magic_context = context;
}

static bool prefix(const char *pre, const char *str)
{
    return strncmp(pre, str, strlen(pre)) == 0;
}

static int filter(cmark_syntax_extension *ext, const unsigned char *tag,
                  size_t tag_len) {
  if (prefix("<img ", (const char *)tag)) {
    cmark_syntax_extension_inlineimage_increment_raw_images_count(ext, 1);
  }

  return 1;
}

cmark_syntax_extension *create_inlineimage_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("inlineimage");
    
    inlineimage_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, release_settings);
    
    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    cmark_syntax_extension_set_html_filter_func(ext, filter);
    
    return ext;
}
