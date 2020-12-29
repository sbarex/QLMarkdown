//
//  heads_utils.cpp
//  QLMarkdown
//
//  Created by Sbarex on 27/12/20.
//

#include "heads_utils.hpp"
#include "string_utils.hpp"
#include <string>
#include <cstring>
#include <string.h>
#include <locale>
#include <codecvt>
#include <iostream>

using namespace std;

char *process_title(const char *title) {
    if (title == nullptr) {
        return nullptr;
    }
    
    std::string current_locale = setlocale(LC_ALL, NULL);
    if (setlocale(LC_ALL, "en_US.UTF-8") == NULL) {
        cerr << "setlocale failed.\n";
    }
    
    string text = title;
    wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
    wstring wParagraph = converter.from_bytes(text);
    
    transform(
              wParagraph.begin(), wParagraph.end(),
              wParagraph.begin(),
              towlower);
    
    wReplaceAll(wParagraph, L" ", L"-");
    
    const wchar_t *input = wParagraph.c_str();
    // Count required buffer size (plus one for null-terminator).
    size_t size = (std::wcslen(input) + 1) * sizeof(wchar_t);
    char *buffer = (char *)calloc(1, size);

    size_t convertedSize;
    #ifdef __STDC_LIB_EXT1__
        // wcstombs_s is only guaranteed to be available if __STDC_LIB_EXT1__ is defined

        std::wcstombs_s(&convertedSize, buffer, size, input, size);
    #else
        convertedSize = std::wcstombs(buffer, input, size);
    #endif
    
    // Restore previous locale.
    setlocale(LC_ALL, current_locale.c_str());
    
    return buffer;
}
