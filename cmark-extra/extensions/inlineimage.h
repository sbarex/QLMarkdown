//
//  inlineimage.h
//  QLMarkdown
//
//  Created by Sbarex on 17/12/20.
//

#ifndef inlineimage_h
#define inlineimage_h

#include <stdio.h>

#include "cmark-gfm-core-extensions.h"

cmark_syntax_extension *create_inlineimage_extension(void);

//! Get the current working directory.
char *cmark_syntax_extension_inlineimage_get_wd(cmark_syntax_extension *extension);
//! Set the current working directory.
void cmark_syntax_extension_inlineimage_set_wd(cmark_syntax_extension *ext, const char *path);

typedef char *(MimeCheck)( const char *filename, void *context );
typedef char *(DataCallback)( const char *url, void *context );

//! Get a mime tester callback.
MimeCheck *cmark_syntax_extension_inlineimage_get_mime_callback(cmark_syntax_extension *extension);
//! Get a mime tester callback extra context.
void *cmark_syntax_extension_inlineimage_get_mime_context(cmark_syntax_extension *extension);
//! Set the mime chceck callback
void cmark_syntax_extension_inlineimage_set_mime_callback(cmark_syntax_extension *extension, MimeCheck *callback, void *context);

typedef void (ProcessFragment)(cmark_syntax_extension *extension, unsigned char *fragment, char *baseDir, void *context, const char **code);

ProcessFragment *cmark_syntax_extension_inlineimage_get_unsafe_html_processor_callback(cmark_syntax_extension *extension);
//! Get the context for processing the raw html fragment.
void *cmark_syntax_extension_inlineimage_get_unsafe_html_context(cmark_syntax_extension *extension);
//! Get the callback for processing the raw html fragment.
void cmark_syntax_extension_inlineimage_set_unsafe_html_processor_callback(cmark_syntax_extension *extension, ProcessFragment *callback, void *context);

DataCallback *cmark_syntax_extension_inlineimage_get_remote_data_callback(cmark_syntax_extension *extension);
void *cmark_syntax_extension_inlineimage_get_remote_data_context(cmark_syntax_extension *extension);
void cmark_syntax_extension_inlineimage_set_remote_data_callback(cmark_syntax_extension *extension, DataCallback *callback, void *context);

/**
 * Get the base64 encoded data for a local image.
 * @param url image url
 * @param mime_callback Optional function to get the mime of the file.
 * @param mime_context Extra argument passed to the mime_callback function.
 * @param remote_callback  Callback for load remote resource
 * @param remote_context Extra argument passed to the remote_callback function.
 * @return The encoded data with mime info to use for the src attribute of <img> tag. ** User must release the returned data.
 *         Return NULL if error occours.
 */
char *get_base64_image(const char *url, MimeCheck *mime_callback, void *mime_context, DataCallback *remote_callback, void *remote_context);

#endif /* inlineimage_h */
