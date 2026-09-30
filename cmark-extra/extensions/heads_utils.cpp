//
//  heads_utils.cpp
//  QLMarkdown
//
//  Created by Sbarex on 27/12/20.
//

#include "heads_utils.hpp"
// #include "string_utils.hpp"

#define PCRE2_LIBRARY 1

#include <string>
#include <codecvt>
#include <iostream>

#ifdef REGEX_LIBRARY
#include <regex>
#endif

#ifdef RE2_LIBRARY
#include "re2.h"
#include <cstring>
#include <locale>
#include <string.h>
#endif

#ifdef PCRE2_LIBRARY
#define PCRE2_CODE_UNIT_WIDTH 32
#include "pcre2.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "jpcre2.hpp"
#pragma clang diagnostic pop

typedef jpcre2::select<wchar_t> jpw;
#endif

#include "c_log.h"
#include "utf8cpp.h"

using namespace std;

// MARK: - String utility

//! Convert a string to a wide string.
static std::wstring stringToWstring(const std::string& t_str)
{
    std::wstring wstr;
    utf8::utf8to16(t_str.begin(), t_str.end(), std::back_inserter(wstr));
    return wstr;
}

//! Convert a wstring to a UTF-8 c string
//! (it depends on the current `LC_CTYPE` locale: **must be an UTF-8 locale**).
//! @return Returns `nullptr` in case of error.
//! **User must release the returned value with `free`.**
static char * wstringToChar(wstring str) {
    // Upper limit: 4 byte for wchar_t + terminator.
    size_t size = str.size() * 4 + 1;
    char *buffer = static_cast<char *>(malloc(size));
    
    size_t n = std::wcstombs(buffer, str.c_str(), size);
    if (n == static_cast<size_t>(-1)) {
        free(buffer);
        return nullptr;
    }
    // wcstombs terminates with '\0' if there is space, and the size guarantees this here.
    return buffer;
}

//! Trim only spaces and tabs (like the CommonMark parser).
//! Safe on UTF-8 because both are ASCII characters.
static std::string trim_spaces(const char *s) {
    const char *begin = s;
    while (*begin == ' ' || *begin == '\t') ++begin;
    
    const char *end = begin + strlen(begin);
    while (end > begin && (end[-1] == ' ' || end[-1] == '\t')) --end;
    
    return std::string(begin, end);
}

//! Trim only spaces and tabs (like the CommonMark parser).
//! Safe on UTF-8 because both are ASCII characters.
static char * c_trim_spaces(const char *s) {
    if (s == nullptr) {
        return nullptr;
    }
    
    const char *begin = s;
    while (*begin == ' ' || *begin == '\t') ++begin;
    
    const char *end = begin + strlen(begin);
    while (end > begin && (end[-1] == ' ' || end[-1] == '\t')) --end;
    
    size_t len = static_cast<size_t>(end - begin);
    char *buffer = static_cast<char *>(malloc(len + 1));
    if (buffer == nullptr) {
        return nullptr;
    }
    memcpy(buffer, begin, len);
    buffer[len] = '\0';
    return buffer;
}

// MARK: - Slug counter

typedef struct {
    char *slug;
    int   count;   // last suffix assigned to the base slug
} SlugEntry;

struct SlugCounter {
    SlugEntry *items;
    size_t     len, cap;
};

//! Initialize the counter.
static void slugcounter_init(SlugCounter *c) {
    c->items = NULL;
    c->len = c->cap = 0;
}

SlugCounter *slugcounter_create() {
    SlugCounter *c = (SlugCounter *)malloc(sizeof(SlugCounter));
    slugcounter_init(c);
    return c;
}

//! Release the items and reset the counter.
void slugcounter_free(SlugCounter *c) {
    if (c == NULL) {
        return;
    }
    for (size_t i = 0; i < c->len; ++i) {
        free(c->items[i].slug);
    }
    free(c->items);
    slugcounter_init(c);
}

static SlugEntry *slugcounter_find(SlugCounter *c, const char *slug) {
    for (size_t i = 0; i < c->len; ++i) {
        if (strcmp(c->items[i].slug, slug) == 0) {
            return &c->items[i];
        }
    }
    return NULL;
}

//! Record a copy of `slug`.
//! @return Return 0 if ok, -1 on out of memory error.
static int slugcounter_add(SlugCounter *c, const char *slug) {
    if (!c || !slug) {
        return -1;
    }
    
    if (c->len == c->cap) {
        size_t ncap = c->cap ? c->cap * 2 : 16;
        SlugEntry *n = (SlugEntry *)realloc(c->items, ncap * sizeof *n);
        if (!n) {
            return -1;
        }
        c->items = n;
        c->cap = ncap;
    }
    
    char *copy = strdup(slug);
    if (!copy) {
        return -1;
    }
    
    c->items[c->len].slug = copy;
    c->items[c->len].count = 0;
    c->len++;
    return 0;
}

//! Return a unique slug ("intro", "intro-1", ...).
//! @param c Slug  counter.
//! @param base The base slug. If it has already been used, it adds a numeric prefix (like `-1`). The first occurrence never has a prefix; from the second onwards, it has a prefix starting at 1.
//! @return `NULL` in case of error. **Release the result with  `free`.**
char *slugcounter_unique(SlugCounter *c, const char *base) {
    if (!base) return NULL;
    
    char *slug = strdup(base);
    if (!slug) return NULL;
    
    if (!c) {
        return slug;
    }
    
    while (slugcounter_find(c, slug)) {
        // Al primo giro slug == base, quindi la entry base esiste.
        SlugEntry *orig = slugcounter_find(c, base);
        orig->count++;
        
        size_t n = strlen(base) + 12;   // "-" + int + '\0'
        char *next = (char *)malloc(n);
        if (!next) {
            free(slug);
            return NULL;
        }
        snprintf(next, n, "%s-%d", base, orig->count);
        free(slug);
        slug = next;
    }
    
    if (slugcounter_add(c, slug) != 0) {
        free(slug);
        return NULL;
    }
    return slug;
}

// MARK: - Slugify

#ifdef REGEX_LIBRARY
//! Approximates [\p{L}\p{M}\p{N}\p{Pc} -].
//! **Require a UTF-8 locale for `iswalnum`.**
static bool is_slug_char(wchar_t c) {
    if (c == L' ' || c == L'-' || c == L'_') return true;
    if (iswalnum(c)) return true;
    // Combining marks (\p{M}): blocchi principali.
    return (c >= 0x0300 && c <= 0x036F)    // Combining Diacritical Marks
    || (c >= 0x1AB0 && c <= 0x1AFF)    // Extended
    || (c >= 0x1DC0 && c <= 0x1DFF)    // Supplement
    || (c >= 0x20D0 && c <= 0x20FF)    // For Symbols
    || (c >= 0xFE20 && c <= 0xFE2F);   // Half Marks
}

//! Process the title with the std::regex.
//! **Works well but only for latin chars.**
//! @return Returns `nullptr` in case of error.
//! **User must release the returned value with `free`.**
static char *process_title_std_regex(const char *title) {
    if (title == nullptr) {
        return nullptr;
    }
    
    wstring text = stringToWstring(trim_spaces(title).c_str());
    
    // locale is reguired by iswalnum and towlower.
    std::string current_locale = setlocale(LC_ALL, NULL);
    if (setlocale(LC_ALL, "en_US.UTF-8") == NULL) {
        cerr << "setlocale failed.\n";
    }
    
    // Filters, replaces spaces with hyphens, and converts to lowercase in a single step.
    wstring out;
    out.reserve(text.size());
    for (wchar_t c : text) {
        if (!is_slug_char(c)) continue;
        out.push_back(c == L' ' ? L'-' : static_cast<wchar_t>(towlower(c)));
    }
    
    char *buffer = wstringToChar(out);
    
    // Restore previous locale.
    setlocale(LC_ALL, current_locale.c_str());
    return buffer;
}
#endif

#ifdef RE2_LIBRARY
//! Slug the title with the re2.
//! **Works well but is slow.**
//! @return Returns `nullptr` in case of error.
//! **User must release the returned value with `free`.**
static char *process_title_re2(const char *title) {
    if (title == nullptr) {
        return nullptr;
    }
    
    string text = trim_spaces(title);
    
    // Removes characters that are not alphanumeric or underscores or spaces or dashes.
    
    // Compile only one time (initializing a static locale is thread-safe on C++11).
    // Tiene: lettere, combining marks, numeri, connector punctuation, spazio, trattino.
    static const RE2 invalidChars_re("[^\\p{L}\\p{M}\\p{N}\\p{Pc} -]+");
    if (!invalidChars_re.ok()) {
        return nullptr;
    }
    
    // Remove invalid chars.
    re2::RE2::GlobalReplace(&text, re, "");
    // Each space becomes a hyphen (a sequence of spaces results in a sequence of hyphens, like on GitHub).
    re2::RE2::GlobalReplace(&text, " ", "-");
    
    wstring wParagraph = stringToWstring(title);
    
    std::string current_locale = setlocale(LC_ALL, NULL);
    if (setlocale(LC_ALL, "en_US.UTF-8") == NULL) {
        cerr << "setlocale failed.\n";
        os_log_error(getLogForHeadsExt(), "`setlocale` failed!");
    }
    
    transform(
              wParagraph.begin(), wParagraph.end(),
              wParagraph.begin(),
              towlower);
    
    char *buffer = wstringToChar(wParagraph);
    
    // Restore previous locale.
    setlocale(LC_ALL, current_locale.c_str());
    
    return buffer;
}
#endif

#ifdef PCRE2_LIBRARY
class PCRE2_re
{
    public:
        jpw::Regex invalidChars_re;
        jpw::Regex spaces_re;
        static PCRE2_re& getInstance()
        {
            static PCRE2_re instance; // Guaranteed to be destroyed.
                                      // Instantiated on first use.
            return instance;
        }
    private:
        PCRE2_re() {
            invalidChars_re
                .setPattern(L"[^\\p{L}\\p{M}\\p{N}\\p{Pc} -]+")
                // not letters (\p{L})
                // not diacritics sign or marks (\p{M})
                // not numbers (\p{N})
                // not underscores or punctuation (\p{Pc})
                // not spaces
                // not dash
                .addModifier("inuS") // i: case insensitive, n: unicode support, u: utf support, S: jit compiler
                .compile();
            
            spaces_re
                // No quantifier: each whitespace maps to one dash, so a run of
                // whitespace yields a run of dashes (GitHub behaviour).
                .setPattern(L"\\s")
                .addModifier("inuS") // i: case insensitive, n: unicode support, u: utf support, S: jit compiler
                .compile();
        }                    // Constructor? (the {} brackets) are needed here.

        // C++ 03
        // ========
        // Don't forget to declare these two. You want to make sure they
        // are inaccessible(especially from outside), otherwise, you may accidentally get copies of
        // your singleton appearing.
        PCRE2_re(PCRE2_re const&);       // Don't Implement
        void operator=(PCRE2_re const&); // Don't implement

        // C++ 11
        // =======
        // We can use the better technique of deleting the methods
        // we don't want.
};


//! Slug the title with the lib pcre2.
//! **Works well and fast.**
//! @return Returns `nullptr` in case of error.
//! **User must release the returned value with `free`.**
static char *process_title_pcre2(const char *title) {
    if (title == nullptr) {
        return nullptr;
    }
    
    wstring text = stringToWstring(trim_spaces(title).c_str());
    
    // Removes characters that are not alphanumeric or spaces or dashes.
    jpw::RegexReplace rr;
    wstring s = rr
        .setRegexObject(&PCRE2_re::getInstance().invalidChars_re)
        .setSubject(text)
        .setReplaceWith(L"")
        .setModifier("g")
        .replace();
    
    // Replace spaces with dashes.
    jpw::RegexReplace rr2;
    wstring s2 = rr2
        .setRegexObject(&PCRE2_re::getInstance().spaces_re)
        .setSubject(s)
        .setReplaceWith(L"-")
        .setModifier("g")
        .replace();
    
    // Change the locale is required by the towlower func
    std::string current_locale = setlocale(LC_ALL, NULL);
    if (setlocale(LC_ALL, "en_US.UTF-8") == NULL) {
        cerr << "setlocale failed.\n";
        // os_log_error(getLogForHeadsExt(), "`setlocale` failed!");
    }
    
    // Lowecase.
    transform(
              s2.begin(), s2.end(),
              s2.begin(),
              towlower);
    
    char *buffer = wstringToChar(s2);
    
    // Restore previous locale.
    setlocale(LC_ALL, current_locale.c_str());
    
    return buffer;
}
#endif

//! Slug a title.
//! - removes characters other than letters, diacritics, numbers, punctuation, spaces, underscore and hyphens.
//! - replace each whitespace to dash.
//! - convert to lowercase.
char *slug_title(const char *title) {
    char *s;
#ifdef RE2_LIBRARY
    s = process_title_re2(title);
#elif REGEX_LIBRARY
    s = process_title_std_regex(title);
#elif PCRE2_LIBRARY
    s = process_title_pcre2(title);
#else
#warning "No regular expression defined!"
    s = nullptr;
#endif
    return s;
}
