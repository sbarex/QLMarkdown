//
//  string_utils.cpp
//  QLMarkdown
//
//  Created by Sbarex on 28/12/20.
//

#include "string_utils.hpp"
#include <string>
#include <cstring>
#include <string.h>
#include <locale>
#include <codecvt>
#include <iostream>

void wReplaceAll(std::wstring& str, const std::wstring& from, const std::wstring& to) {
    if (from.empty()) {
        return;
    }
    size_t start_pos = 0;
    while ((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length(); // In case 'to' contains 'from', like replacing 'x' with 'yx'
    }
} 

void replaceAll(std::string& str, const std::string& from, const std::string& to) {
    if (from.empty()) {
        return;
    }
    size_t start_pos = 0;
    while((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length(); // In case 'to' contains 'from', like replacing 'x' with 'yx'
    }
}
