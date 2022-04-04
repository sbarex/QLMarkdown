//
//  MIMEType.h
//  QLMarkdown
//

#ifndef MIMEType_h
#define MIMEType_h



#ifdef __cplusplus
extern "C" {
#endif

typedef enum MIME_MAGICK_CHECK {
    MAGIC_NOT_CHECKED = 0,
    MAGIC_FALLBACK_CHECK = 1,
    MAGIC_CONFRONT = 2
} MIME_MAGICK_CHECK;

/**
 * Get the mime type of a file.
 * The type is derived from the file extension, but you can also check the magic code on the header of the file.
 * @param path Path of the file.
 * @param check_magic Flag to analyze the magic code.
 * - MAGIC_NOT_CHECKED: do not analyze the magic code.
 * - MAGIC_FALLBACK_CHECK: analyze the magic code only if the extension is unknown.
 * - MAGIC_CONFRONT: alway analyze the magic code and compare with the type detected from the extension. The two types must have the same prefix, otherwise return NULL.
 * @returns Return the detected mime type or NULL if it is unknown. **User must release the returned value.**
 */
char *get_mime(const char *path, MIME_MAGICK_CHECK check_magic);

char *get_mime_from_buffer(const char *ext, const char *buffer, MIME_MAGICK_CHECK check_magic);
    
#ifdef __cplusplus
}
#endif
#endif /* MIMEType_h */
