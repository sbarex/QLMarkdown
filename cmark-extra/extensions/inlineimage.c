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
#include <sys/stat.h>
#include <limits.h>
#include <stdbool.h>
#include <ctype.h>
#include <curl/curl.h>

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

static inlineimage_settings *init_settings(void) {
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


#define INLINEIMAGE_MAX_BYTES (64L * 1024 * 1024)

/** True when `resolved` (a realpath) is `base_real` itself or sits inside it. */
static bool path_is_within(const char *resolved, const char *base_real) {
    size_t n = strlen(base_real);
    if (n == 0) {
        return false;
    }
    if (strncmp(resolved, base_real, n) != 0) {
        return false;
    }
    if (base_real[n - 1] == '/') {
        return true; // base is the root directory.
    }
    return resolved[n] == '/' || resolved[n] == '\0';
}

/**
 * Detect an image from the file content (magic bytes), never from its name.
 * A name-derived type lets any file pass as `image/...`, so it is not a check.
 * @returns a static mime string, or NULL when the content is not a known image.
 */
static const char *sniff_image_mime(const unsigned char *b, size_t len) {
    if (len >= 8 && memcmp(b, "\x89PNG\r\n\x1a\n", 8) == 0) return "image/png";
    if (len >= 3 && memcmp(b, "\xFF\xD8\xFF", 3) == 0) return "image/jpeg";
    if (len >= 6 && (memcmp(b, "GIF87a", 6) == 0 || memcmp(b, "GIF89a", 6) == 0)) return "image/gif";
    if (len >= 2 && memcmp(b, "BM", 2) == 0) return "image/bmp";
    if (len >= 4 && (memcmp(b, "II\x2a\x00", 4) == 0 || memcmp(b, "MM\x00\x2a", 4) == 0)) return "image/tiff";
    if (len >= 12 && memcmp(b, "RIFF", 4) == 0 && memcmp(b + 8, "WEBP", 4) == 0) return "image/webp";
    if (len >= 4 && memcmp(b, "\x00\x00\x01\x00", 4) == 0) return "image/x-icon";
    if (len >= 12 && memcmp(b + 4, "ftyp", 4) == 0) {
        if (memcmp(b + 8, "avif", 4) == 0 || memcmp(b + 8, "avis", 4) == 0) return "image/avif";
        if (memcmp(b + 8, "heic", 4) == 0 || memcmp(b + 8, "heix", 4) == 0 || memcmp(b + 8, "mif1", 4) == 0 || memcmp(b + 8, "msf1", 4) == 0) return "image/heic";
    }
    // SVG is text: accept it only when an <svg> tag appears near the top.
    size_t i = 0;
    if (len >= 3 && memcmp(b, "\xEF\xBB\xBF", 3) == 0) {
        i = 3; // skip the BOM
    }
    while (i < len && isspace(b[i])) {
        i++;
    }
    if (len - i >= 5 && (memcmp(b + i, "<?xml", 5) == 0 || memcmp(b + i, "<svg", 4) == 0)) {
        size_t n = len < 4096 ? len : 4096;
        for (size_t j = i; j + 4 <= n; j++) {
            if (memcmp(b + j, "<svg", 4) == 0) {
                return "image/svg+xml";
            }
        }
    }
    return NULL;
}

/**
 * Read a local image and return it as a `data:` URI.
 * The file must resolve inside `base_dir` (the document folder) and must be a regular
 * file whose content is a known image type. Otherwise nothing is inlined: a previewed
 * document must not be able to pull arbitrary files into the rendered page.
 * @returns the data URI, or NULL. **The caller must release the returned value.**
 */
static char *read_local_image_as_data_uri(const char *image_path, const char *base_dir) {
    char resolved[PATH_MAX];
    if (realpath(image_path, resolved) == NULL) {
        os_log_error(getLogForImageExt(), "Unable to resolve file %{public}s: %{public}s (%{public}d)!", image_path, strerror(errno), errno);
        return NULL;
    }
    if (base_dir != NULL && base_dir[0] != '\0') {
        char base_real[PATH_MAX];
        if (realpath(base_dir, base_real) == NULL || !path_is_within(resolved, base_real)) {
            os_log_error(getLogForImageExt(), "%{public}s is outside the document directory, not inlined!", resolved);
            return NULL;
        }
    }
    
    FILE *f = fopen(resolved, "rb");
    if (!f) {
        os_log_error(getLogForImageExt(), "Unable to open file %{public}s: %{public}s (%{public}d)!", resolved, strerror(errno), errno);
        return NULL;
    }
    struct stat st;
    if (fstat(fileno(f), &st) != 0 || !S_ISREG(st.st_mode) || st.st_size <= 0 || st.st_size > INLINEIMAGE_MAX_BYTES) {
        os_log_error(getLogForImageExt(), "%{public}s is not a regular file of usable size, not inlined!", resolved);
        fclose(f);
        return NULL;
    }
    size_t length = (size_t)st.st_size;
    unsigned char *buffer = malloc(length);
    if (!buffer) {
        fclose(f);
        return NULL;
    }
    size_t got = fread(buffer, 1, length, f);
    fclose(f);
    if (got != length) {
        os_log_error(getLogForImageExt(), "Unable to read file %{public}s!", resolved);
        free(buffer);
        return NULL;
    }
    
    const char *mime = sniff_image_mime(buffer, got);
    if (mime == NULL) {
        os_log_error(getLogForImageExt(), "%{public}s is not an image, not inlined!", resolved);
        free(buffer);
        return NULL;
    }
    
    char *data = b64_encode(buffer, length);
    free(buffer);
    if (!data) {
        return NULL;
    }
    char *encoded = (char *)calloc(strlen(mime) + strlen("data:;base64,") + strlen(data) + 1, sizeof(char));
    if (encoded) {
        sprintf(encoded, "data:%s;base64,%s", mime, data);
    }
    free(data);
    return encoded;
}

char *get_base64_image(const char *url, const char *base_dir, MimeCheck *mime_callback, void *mime_context, DataCallback *remote_callback, void *remote_context) {
    char *protocol = NULL, *host = NULL, *path = NULL, *query = NULL;
    const char *image_path;
    char *mime = NULL;
    char *encoded = NULL;
    
    char *decoded = curl_easy_unescape(NULL, url, 0, NULL);
    parse_url(decoded, &protocol, &host, &path, &query);
    
    if (strcmp(protocol, "file") == 0) {
        // The url path is the local file path.
        image_path = path;
    } else if (strlen(host) == 0) {
        // No host, the url is a local file path.
        image_path = (const char *)decoded;
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
    
    // Local files are validated and read by read_local_image_as_data_uri(): the mime callback
    // cannot be used to authorise a non-image or a file outside the document folder.
    encoded = read_local_image_as_data_uri(image_path, base_dir);
    
continue_loop:
    free(mime);
    
    free(protocol);
    free(path);
    free(host);
    free(query);
    curl_free(decoded);
    
    return encoded;
}

char *get_base64_image2(const char *url, const char *mime, const char *base_dir, DataCallback *remote_callback, void *remote_context) {
    char *protocol = NULL, *host = NULL, *path = NULL, *query = NULL;
    const char *image_path;
    char *encoded = NULL;
    
    char *decoded = curl_easy_unescape(NULL, url, 0, NULL);
    parse_url(decoded, &protocol, &host, &path, &query);
    
    if (strcmp(protocol, "file") == 0) {
        // The url path is the local file path.
        image_path = path;
    } else if (strlen(host) == 0) {
        // No host, the url is a local file path.
        image_path = (const char *)decoded;
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
    
    
    // `mime` is derived from the file name by the caller and is therefore not a check;
    // read_local_image_as_data_uri() confines the path and identifies the image by content.
    (void)mime;
    encoded = read_local_image_as_data_uri(image_path, base_dir);
    
continue_loop:
    free(protocol);
    free(path);
    free(host);
    free(query);
    curl_free(decoded);
    
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
            
            if (mime_callback) {
                encoded = get_base64_image(url, basedir, mime_callback, mime_context, data_callback, data_context);
            } else {
                char *mime = mime_from_image_name(url);
                encoded = get_base64_image2(url, mime, basedir, data_callback, data_context);
                free(mime);
            }
            
            if (encoded != NULL) {
                cmark_mem *mem = cmark_get_default_mem_allocator();
                // Replace the original url with the encoded data.
                // cmark_chunk_set_cstr copies its argument, so pass url directly
                // (a strdup here would be copied and then leaked).
                cmark_chunk_set_cstr(mem, &node->as.link.title, url);
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


char *mime_from_image_name(const char *image_path) {
    if (!image_path) return NULL;
    
    // Trova l'ultimo '.' nella stringa
    const char *dot = strrchr(image_path, '.');
    
    // Nessun punto o punto all'inizio (es. ".gitignore")
    if (!dot || dot == image_path) {
        return NULL;
    }

    // Se il punto è l'ultimo carattere ("file.")
    if (*(dot + 1) == '\0') {
        return NULL;
    }
    
    const char *ext = dot + 1;
    
    if (strcmp(ext, "jpg") == 0) {
        return strdup("image/jpeg");
    } else if (strcmp(ext, "tif") == 0) {
        return strdup("image/tiff");
    } else if (strcmp(ext, "svg") == 0) {
        return strdup("image/svg+xml");
    }

    size_t len = strlen(ext) + 7; // "image/" + ext + '\0'
    char *mime = malloc(len);
    if (!mime) return NULL;

    snprintf(mime, len, "image/%s", ext);
    return mime;
}
