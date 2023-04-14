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
#include <os/log.h>

#include "c_log.h"

// #include <curl/curl.h>
#include <libgen.h>
#include <ctype.h>

static inline void lowercase(char *s){
    while (*s) {
        *s = tolower(*s);
        ++s;
    }
}

typedef struct {
    char *path;
    MimeCheck *magic_callback;
    void *magic_context;
    DataCallback *data_callback;
    void *data_context;
    
    int raw_images;
    ProcessFragment *html_callback;
    void *html_context;
} inlineimage_settings;

static inlineimage_settings *init_settings() {
    cmark_mem *mem = cmark_get_default_mem_allocator();
    inlineimage_settings *settings = mem->calloc(1, sizeof(inlineimage_settings));
    settings->path = NULL;
    settings->magic_callback = NULL;
    settings->magic_context = NULL;
    
    settings->data_callback = NULL;
    settings->data_context = NULL;
    
    settings->html_callback = NULL;
    settings->html_context = NULL;
    
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
        
        settings->data_callback = NULL;
        settings->data_context = NULL;
        
        settings->html_callback = NULL;
        settings->html_context = NULL;
        
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

/*
struct MemoryStruct {
  char *memory;
  size_t size;
};
 
static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    struct MemoryStruct *mem = (struct MemoryStruct *)userp;
 
    char *ptr = mem->memory != NULL ? realloc(mem->memory, mem->size + realsize + 1) : malloc(mem->size + realsize + 1);
    if(!ptr) {
        // out of memory!
        printf("not enough memory (realloc returned NULL)\n");
        return 0;
    }
 
    mem->memory = ptr;
    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;
 
    return realsize;
}

char *fetch_remote(const char *url, int *status, size_t *size) {
    CURL *curl_handle;
    CURLcode res;
    
    struct MemoryStruct chunk;
     
    chunk.memory = NULL;  // will be grown as needed by the realloc above
    chunk.size = 0;    // no data at this point
     
    curl_global_init(CURL_GLOBAL_ALL);
     
    // init the curl session
    curl_handle = curl_easy_init();
     
    // specify URL to get
    curl_easy_setopt(curl_handle, CURLOPT_URL, url);
     
    // send all data to this function
    curl_easy_setopt(curl_handle, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
     
    // we pass our 'chunk' struct to the callback function
    curl_easy_setopt(curl_handle, CURLOPT_WRITEDATA, (void *)&chunk);
     
    // some servers do not like requests that are made without a user-agent
         field, so we provide one
    curl_easy_setopt(curl_handle, CURLOPT_USERAGENT, "libcurl-agent/1.0");
     
    // get it!
    res = curl_easy_perform(curl_handle);
     
    // check for errors
    if (res != CURLE_OK) {
         fprintf(stderr, "curl_easy_perform() failed: %s\n",
                curl_easy_strerror(res));
    } else {
        // Now, our chunk.memory points to a memory block that is chunk.size
        // bytes big and contains the remote file.
        //
        // Do something nice with it!
        printf("%lu bytes retrieved\n", (unsigned long)chunk.size);
    }
     
    // cleanup curl stuff
    curl_easy_cleanup(curl_handle);
     
    // we are done with libcurl, so clean it up
    curl_global_cleanup();
    *status = res;
    *size = chunk.size;
    return chunk.memory;
}
*/

char *get_base64_image(const char *url, MimeCheck *mime_callback, void *mime_context, DataCallback *remote_callback, void *remote_context) {
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
        if (remote_callback != NULL) {
            char *buffer = remote_callback(url, remote_context);
            if (buffer == NULL) {
                goto continue_loop;
            }
            char temp[strlen(path)+1], *fname, *ext;
            strcpy(temp, path); //todo rewrite own basename to take const char*
            fname = basename(temp);
            ext = strchr(fname, '.');
            if (ext == NULL) {
                ext = fname;
            } else {
                ext++; // skip the dot
            }
            lowercase(ext);
            
            mime  = get_mime_from_buffer(ext, buffer, 2);
            
            char *data = b64_encode((const unsigned char *)buffer, strlen(buffer));
            size_t encoded_length = strlen(data);
            
            encoded = (char *)calloc(strlen(mime) + strlen("data:;base64,") + encoded_length + 1, sizeof(char));
            sprintf(encoded, "data:%s;base64,%s", mime, data);
            
            free(data);
            free(buffer);
            
            goto continue_loop;
        } else {
            // Not a local file.
            goto continue_loop;
        }
    }
    
    if (access(image_path, F_OK | R_OK) == 0) {
        if (mime_callback != NULL) {
            mime = mime_callback(image_path, mime_context);
        } else {
            mime = get_mime(image_path, 2);
        }
        if (!mime || !startsWith("image/", mime)) {
            os_log_error(getLogForImageExt(), "%{private}s (%{public}s) is not an image!", image_path, mime);
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
            os_log_error(getLogForImageExt(), "Error to get magic for file %{private}s:, %{public}s (%{public}d)!", image_path, strerror(errno), errno);
            fprintf(stderr, "Error to get magic for file %s: %s (#%d)!\n", image_path, strerror(errno), errno);
        }
    } else {
        os_log_error(getLogForImageExt(), "Unable to open file %{private}s: %{public}s (%{public}d)!", image_path, strerror(errno), errno);
        fprintf(stderr, "Unable to open file %s: %s (#%d)!\n", image_path, strerror(errno), errno);
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
    
    ProcessFragment *html_callback = cmark_syntax_extension_inlineimage_get_unsafe_html_processor_callback(ext);
    void *html_context = html_callback != NULL ? cmark_syntax_extension_inlineimage_get_unsafe_html_context(ext) : NULL;
    
    while ((ev = cmark_iter_next(iter)) != CMARK_EVENT_DONE) {
        node = cmark_iter_get_node(iter);
        
        // cmark_node_type type;
        // type = node->type;
        
        if (ev != CMARK_EVENT_ENTER) {
            continue;
        }
        
        if (node->type == CMARK_NODE_IMAGE) {
            const char *url = (const char *)node->as.link.url.data;
            char *encoded = NULL;
            
            MimeCheck *mime_callback = cmark_syntax_extension_inlineimage_get_mime_callback(ext);
            void *mime_context = cmark_syntax_extension_inlineimage_get_mime_context(ext);
            
            DataCallback *data_callback = cmark_syntax_extension_inlineimage_get_remote_data_callback(ext);
            void *data_context = cmark_syntax_extension_inlineimage_get_remote_data_context(ext);
            
            encoded = get_base64_image(url, mime_callback, mime_context, data_callback, data_context);
            
            if (encoded != NULL) {
                cmark_mem *mem = cmark_get_default_mem_allocator();
                // Replace the original url with the encoded data.
                cmark_chunk_set_cstr(mem, &node->as.link.url, encoded);
                free(encoded);
            }
        } else if ((node->type == CMARK_NODE_HTML_BLOCK || node->type == CMARK_NODE_HTML_INLINE) && html_callback != NULL) {
            // Search inside the raw html fragment and process the images.
            cmark_chunk_to_cstr(parser->mem, &node->as.literal);
            unsigned char *s = NULL;
            html_callback(ext, node->as.literal.data, (char *)basedir, html_context, (const char **)&s);
            if (s != NULL) {
                // printf("%s", s);
                cmark_chunk_set_cstr(parser->mem, &node->as.literal, (const char *)s);
                free(s);
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


DataCallback *cmark_syntax_extension_inlineimage_get_remote_data_callback(cmark_syntax_extension *extension)
{
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (settings) {
        return settings->data_callback;
    } else {
        return NULL;
    }
}

void *cmark_syntax_extension_inlineimage_get_remote_data_context(cmark_syntax_extension *extension) {
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (settings) {
        return settings->data_context;
    } else {
        return NULL;
    }
}

void cmark_syntax_extension_inlineimage_set_remote_data_callback(cmark_syntax_extension *extension, DataCallback *callback, void *context) {
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, release_settings);
    }
    settings->data_callback = callback;
    settings->data_context = context;
}

ProcessFragment *cmark_syntax_extension_inlineimage_get_unsafe_html_processor_callback(cmark_syntax_extension *extension)
{
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (settings) {
        return settings->html_callback;
    } else {
        return NULL;
    }
}
void *cmark_syntax_extension_inlineimage_get_unsafe_html_context(cmark_syntax_extension *extension)
{
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (settings) {
        return settings->html_context;
    } else {
        return NULL;
    }
}
void cmark_syntax_extension_inlineimage_set_unsafe_html_processor_callback(cmark_syntax_extension *extension, ProcessFragment *callback, void *context)
{
    inlineimage_settings *settings = (inlineimage_settings *)cmark_syntax_extension_get_private(extension);
    if (!settings) {
        settings = init_settings();
        cmark_syntax_extension_set_private(extension, settings, release_settings);
    }
    settings->html_callback = callback;
    settings->html_context = context;
}
cmark_syntax_extension *create_inlineimage_extension(void)
{
    cmark_syntax_extension *ext = cmark_syntax_extension_new("inlineimage");
    
    inlineimage_settings *settings = init_settings();
    cmark_syntax_extension_set_private(ext, settings, release_settings);
    
    cmark_syntax_extension_set_postprocess_func(ext, postprocess);
    
    return ext;
}
