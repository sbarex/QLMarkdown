//
//  string_utils.hpp
//  QLMarkdown
//
//  Created by Sbarex on 28/12/20.
//

#ifndef string_utils_hpp
#define string_utils_hpp

#include <string>

#ifdef __cplusplus
extern "C" {
#endif
void wReplaceAll(std::wstring& str, const std::wstring& from, const std::wstring& to);

void replaceAll(std::string& str, const std::string& from, const std::string& to);

#ifdef __cplusplus
}
#endif

#endif /* string_utils_hpp */
