//
//  heads_utils.cpp
//  QLMarkdown
//
//  Created by Sbarex on 27/12/20.
//

#include "heads_utils.hpp"
#include "string_utils.hpp"

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

using namespace std;

//! Convert a string to a wide string.
static std::wstring stringToWstring(const std::string& t_str)
{
    //setup converter
    typedef std::codecvt_utf8<wchar_t> convert_type;
    std::wstring_convert<convert_type, wchar_t> converter;

    //use converter (.to_bytes: wstr->str, .from_bytes: str->wstr)
    return converter.from_bytes(t_str);
}

//! Convert a wide string to a c string.
//! **User must release the returned value.**
static char * wstringToChar(wstring str) {
    const wchar_t *input = str.c_str();

    // Count required buffer size (plus one for null-terminator).
    size_t size = (wcslen(input) + 1) * sizeof(wchar_t);
    char *buffer = new char[size];

    #ifdef __STDC_LIB_EXT1__
        // wcstombs_s is only guaranteed to be available if __STDC_LIB_EXT1__ is defined
        size_t convertedSize;
        std::wcstombs_s(&convertedSize, buffer, size, input, size);
    #else
        std::wcstombs(buffer, input, size);
    #endif
    return buffer;
}

#ifdef REGEX_LIBRARY
//! Process the title with the std::regex. **Works well but only for latin chars.**
//! **User must release the returned value.**
static char *process_title_std_regex(const char *title) {
    if (title == nullptr) {
        return nullptr;
    }
    
    wstring text3 = stringToWstring(title);
    // 背景介绍
    std::locale::global(std::locale("en_US.UTF-8"));
    // Lowercase
    transform(text3.begin(), text3.end(), text3.begin(), towlower);
    // Removes characters that are not alphanumeric or spaces or dashes.
    std::wregex pattern(L"[^_[:alnum:] -]+", std::regex_constants::extended);
    text3 = std::regex_replace(text3, pattern, L"");
    // Replace spaces with dashes.
    text3 = std::regex_replace(text3, std::wregex(L" "), L"-");
    
    char *buffer = wstringToChar(text3);
    return buffer;
}
#endif

#ifdef RE2_LIBRARY
//! Process the title with the re2. **Works well but is slow.**
//! **User must release the returned value.**
static char *process_title_re2(const char *title) {
    if (title == nullptr) {
        return nullptr;
    }
    
    std::string current_locale = setlocale(LC_ALL, NULL);
    if (setlocale(LC_ALL, "en_US.UTF-8") == NULL) {
        cerr << "setlocale failed.\n";
    }
    
    string text = title;
    
    // Removes characters that are not alphanumeric or spaces or dashes.
    RE2 re("[^\\p{L}\\p{N} -]+");
    if (!re.ok()) {
        return nullptr;
    }
    re2::RE2::GlobalReplace(&text, re, "");
    // Replace spaces with dashes.
    re2::RE2::GlobalReplace(&text, " ", "-");
    
    wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    wstring wParagraph;
    try {
        wParagraph = converter.from_bytes(text);
    } catch (const std::range_error& e) {
        return nullptr;
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
                .setPattern(L"[^\\p{L}\\p{N} -]+") // Not letters, not numbers, not spaces, not dash.
                .addModifier("inuS") // i: case insensitive, n: unicode support, u: utf support, S: jit compiler
                .compile();
            
            spaces_re
                .setPattern(L"\\s+")
                .addModifier("inuS") // i: case insensitive, n: unicode support, u: utf support, S: jit compiler
                .compile();
        }                    // Constructor? (the {} brackets) are needed here.

        // C++ 03
        // ========
        // Don't forget to declare these two. You want to make sure they
        // are inaccessible(especially from outside), otherwise, you may accidentally get copies of
        // your singleton appearing.
        PCRE2_re(PCRE2_re const&);              // Don't Implement
        void operator=(PCRE2_re const&); // Don't implement

        // C++ 11
        // =======
        // We can use the better technique of deleting the methods
        // we don't want.
};


//! Process the title with the lib pcre2. **Works well and fast.**
//! **User must release the returned value.**
static char *process_title_pcre2(const char *title) {
    if (title == nullptr) {
        return nullptr;
    }
    
    wstring text = stringToWstring(title);
    
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
    
    // Lowecase.
    transform(
              s2.begin(), s2.end(),
              s2.begin(),
              towlower);
    
    char *buffer = wstringToChar(s2);
    return buffer;
}
#endif

char *process_title(const char *title) {
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
