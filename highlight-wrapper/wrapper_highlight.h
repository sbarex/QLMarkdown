#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedGlobalDeclarationInspection"
#ifndef WRAPPER_HIGHLIGHT_H
#define WRAPPER_HIGHLIGHT_H

#define EXPORT __attribute__((visibility("default")))

#ifdef __cplusplus
extern "C" {
#endif

/*!
 * Info about a theme.
 */
typedef struct HThemeInfo {
    char *name;
    char *desc;
    char *path; /*!< Full path of the theme file. */
    int base16;
    int appearance;
} HThemeInfo;

/*!
 * Single property of a theme.
 */
typedef struct HThemeProperty {
    char *color;
    int bold; /*!< 0: false, 1: true, -1: not defined */
    int italic;
    int underline;
} HThemeProperty;

enum HThemeAppearance { not_set = 0, light = 1, dark = 2 };

/*!
 * HTheme.
 */
typedef struct HTheme {
    char *name;
    char *desc;
    char *path;
    enum HThemeAppearance appearance;
    int standalone;
    int base16;

    HThemeProperty *plain;
    HThemeProperty *canvas;
    HThemeProperty *number;
    HThemeProperty *string;
    HThemeProperty *escape;
    HThemeProperty *preProcessor;
    HThemeProperty *stringPreProc;
    HThemeProperty *blockComment;
    HThemeProperty *lineComment;
    HThemeProperty *lineNum;
    HThemeProperty *operatorProp;
    HThemeProperty *interpolation;

    int keyword_count;
    HThemeProperty **keywords;
} HTheme;

typedef void (*ResultCallback)( void* context, const char* result, int error);
/*!
 * Callback function to handle the result of highlight_list_themes.
 *
 * @see highlight_list_themes
 */
typedef void (*ResultThemeListCallback)(void* context, const HThemeInfo **themes, int count, int exit_code);

typedef void (* ReleaseTheme)(HTheme *theme);
typedef void (* ReleaseThemeInfo)(HThemeInfo *theme);
typedef void (* ReleaseThemeInfoList)(HThemeInfo **themes, int count);

/*!
 * Callback function to handle the request of a theme info.
 * @see highlight_theme_info
 */
typedef void (*ResultThemeCallback)(void* context, const HTheme *theme, int exit_code);

EXPORT char *get_highlight_version(void);
EXPORT char *get_highlight_website(void);
EXPORT char *get_highlight_email(void);

EXPORT const char *get_lua_info(void);

/*!
 * Initialize the highlight context with the provided path.
 * This function must be always called one time before all others.
 * @param search_dir Path of folder that contain filetypes.conf file and the directories langDefs, themes, plugins.
 *
 * @see highlight_init_generator
 */
EXPORT void highlight_init(const char *search_dir);

/*!
 * Init the generator.
 * Previous initialized generator is released.
 * @return EXIT_SUCCESS or EXIT_FAILURE
 *
 * @see highlight_release_generator
 */
int highlight_init_generator(void);

/*!
 * Free the memory used by the generator if no more rendering is required.
 */
EXPORT void highlight_release_generator(void);

/*!
 * Get current theme full path.
 * @return The returned pointer is not guaranteed to remain valid over the time. Please consider to retain a copy.
 */
EXPORT const char *highlight_get_current_theme(void);

/*!
 * Set a new theme.
 * @param theme Name or full file path. If the theme is already in use it does nothing.
 * @return EXIT_SUCCESS or EXIT_FAILURE.
 */
EXPORT int highlight_set_current_theme(const char *theme);

/**
 * Get the font name used for the output. Is the value used by font-family css style.
 * @return Font size. **Remember to release the pointer. **
 * @return The font name.
 */
EXPORT char *highlight_get_current_font(void);

/*!
 * Set the font name used for the output.
 * @param font Font name
 * @param font_size If not NULL set also the font size.
 */
EXPORT void highlight_set_current_font(const char *font, const char *font_size);

/*!
 * Get the font size used for the output.
 * @return Font size. **Remember to release the pointer. **
 */
EXPORT char *highlight_get_current_font_size(void);

/**
 * Set the font size used for the output.
 * @param font_size Font size.
 */
EXPORT void highlight_set_current_font_size(const char *font_size);

/**
 * Return if the line numbers are presents in the output.
 * @return 0 = off, 1 = on
 */
EXPORT int highlight_get_print_line_numbers(void);
/**
 * Set if the line numbers are presents in the output.
 * @param state 0 = off, 1 = on
 */
EXPORT void highlight_set_print_line_numbers(int state);

/*!
 * Set the formatting mode. Call this function after highlight_set_print_line_numbers.
 * @param wrap_at_characters Wrap lines after this number o characters. Set to zero to disable the wrap mode.
 * @param tab_replace_spaces Number of spacew used to replace a tabs. Set to zero to disable the replace,
 */
EXPORT void highlight_set_formatting_mode(int wrap_at_characters, int tab_replace_spaces);

/*!
 * Format a source code.
 * @param code Code to highlight.
 * @param language Language to recognize the format.
 * @param export_fragment Export only a fragment or the entire html document.
 * @param context Custom context to pass to the callback.
 * @param callback Callback that receive the formatted code.
 *
 * @see highlight_format_string2
 */
EXPORT void highlight_format_string(const char *code, const char *language, void *context, ResultCallback callback, int export_fragment);

/*!
 * Format a source code. The returned string must be release by the user.
 * @param code Code to highlight.
 * @param language Language to recognize the format.
 * @param exit_code EXIT_SUCCESS if no error.
 * @param export_fragment Export only a fragment or the entire html document.
 * @return The formatted code. **You are responsible for the memory deallocation**.
 */
EXPORT char *highlight_format_string2(const char *code, const char *language, int *exit_code, int export_fragment);

/*!
 * Get the CSS style code.
 * @param context Custom context to pass to the callback.
 * @param callback Callback that receive the formatted code.
 * @param background Override the background color.
 * Pass NULL to do not override, an empty string remove the color, other value is used as new color.
 *
 * @see highlight_format_style2
 */
EXPORT void highlight_format_style(void *context, ResultCallback callback, const char *background);

/*!
 * Get the CSS style code.
 * @param exit_code EXIT_SUCCESS if no error.
 * @param background Override the background color.
 * Pass NULL to do not override, an empty string remove the color, other value is used as new color.
 * @return The formatted code. **You are responsible for the memory deallocation**.
 *
 * @see highlight_format_style
 */
EXPORT char *highlight_format_style2(int *exit_code, const char *background);

/*!
 * Get a list of the predefined themes.
 * @param context Custom context to pass to the callback.
 * @param callback Callback to pass the theme list.
 * @return EXIT_SUCCESS on success.
 *
 * @see highlight_list_themes2
 */
EXPORT int highlight_list_themes( void *context, ResultThemeListCallback callback);

/*!
 * Get a list of the predefined themes.
 * @param theme_list List of detected themes.
 * @param count Number of themes.
 * @param release Function to call to release the theme list. **You must release the memory with the function received in the release argument.**
 * @return EXIT_SUCCESS if no error.
 *
 * @see highlight_list_themes
 */
EXPORT int highlight_list_themes2(HThemeInfo ***theme_list, int *count, ReleaseThemeInfoList *release);

/*!
 * Get the properties of a theme.
 * @param theme Name of the theme or the full path.
 * @param context Custom context to pass to the callback.
 * @param callback Callback that receive the formatted code.
 * @return EXIT_SUCCESS on success.
 */
EXPORT int highlight_get_theme( const char *theme, void *context, ResultThemeCallback callback);
/*!
 * Get the properties of a theme.
 * @param theme Name of the theme or the full path.
 * @param exit_code EXIT_SUCCESS if no error.
 * @param release Function to call to release the returned value.
 * @return The theme info. **You must release the memory with the function received in the release argument.**
 */
EXPORT HTheme *highlight_get_theme2(const char *theme, int *exit_code, ReleaseTheme *release);

/*!
 * Store the theme inside a file.
 * @param filename Destination file name.
 * @param theme HTheme to store.
 * @return EXIT_SUCCESS on success.
 */
EXPORT int highlight_save_theme( const char *filename, const HTheme *theme);

/**
 * Try to guess the language with magic library
 * @param buffer Source code to analyze.
 * @param magic_database Location of the magic mgc database definition. Pass NULL to use the system file.
 * @return The Language guessed or NULL. **The user must free the result.**
 */
EXPORT char *magic_guess_language(const char *buffer, const char *magic_database);

/**
 * Try to guess the language with Enry engine
 * @param buffer Source code to analyze.
 * @return The Language guessed or NULL. **The user must free the result.**
 */
EXPORT char *enry_guess_language(const char *buffer);

#ifdef __cplusplus
}
#endif

#endif
#pragma clang diagnostic pop
